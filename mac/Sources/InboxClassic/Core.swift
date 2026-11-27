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
    /// the Message-ID of a draft, for DraftSaved; the notification's text, for NewMail (`message` its title); the
    /// view's preview token, for PreviewsPrepared
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

/// Runs `block` on the main thread after `seconds`, also while a modal window runs; the timer, to stop it before
@discardableResult
func after(_ seconds: TimeInterval, _ block: @escaping @MainActor () -> Void) -> Timer {
    let timer = Timer(timeInterval: seconds, repeats: false) { _ in MainActor.assumeIsolated { block() } }
    RunLoop.main.add(timer, forMode: .common)
    return timer
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

    /// Settings > Reading > Encryption: "Search in encrypted messages"; off takes their decrypted text out of the index
    var searchEncrypted: Bool {
        get { pe_pgp_index_encrypted(handle) }
        set { _ = pe_pgp_set_index_encrypted(handle, newValue) }
    }

    /// Settings > Reading > Encryption: "Look up keys on keys.openpgp.org"
    var keyserver: Bool {
        get { pe_pgp_keyserver(handle) }
        set { _ = pe_pgp_set_keyserver(handle, newValue) }
    }

    /// Settings' "Show messages on a dark background when the system is dark", for the documents built from then on
    var darkMessages: Bool {
        get { pe_dark_messages(handle) }
        set { _ = pe_set_dark_messages(handle, newValue) }
    }

    /// Settings' "Show attachments in messages", and under it "Show PDF files in messages"
    var showPreviews: Bool {
        get { pe_show_previews(handle) }
        set { _ = pe_set_show_previews(handle, newValue) }
    }

    var pdfPreviews: Bool {
        get { pe_pdf_previews(handle) }
        set { _ = pe_set_pdf_previews(handle, newValue) }
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

    /// Settings' "Wait before sending": its place among `Core.sendDelays`
    var sendDelayIndex: Int {
        get { pe_send_delay_index(handle) }
        set { pe_set_send_delay_index(handle, newValue) }
    }

    /// The waits before a message goes that Settings offers, in words ("Off", "10 seconds")
    static var sendDelays: [String] {
        (0..<pe_send_delay_count()).map { taken(pe_send_delay_text($0)) ?? "" }
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
        guard let list = pe_folders(handle, account) else { return [] }
        defer { pe_folder_list_free(list) }
        return (0..<pe_folder_list_count(list)).compactMap { pe_folder_list_get(list, $0).map { Folder($0.pointee) } }
    }

    /// the rows of the folder list, in its order, as the core lays it out, and the row to choose given the key of the
    /// row chosen before (nil when that folder is gone or nothing was chosen)
    func folderTree(chosen key: String?) -> (rows: [TreeRow], chosen: Int?) {
        guard let tree = pe_folder_tree(handle) else { return ([], nil) }
        defer { pe_tree_free(tree) }
        let rows = (0..<pe_tree_count(tree)).compactMap { pe_tree_get(tree, $0).map { TreeRow($0.pointee) } }
        guard let key else { return (rows, nil) }
        let index = key.withCString { pe_tree_reselect(tree, $0) }
        return (rows, index >= 0 ? Int(index) : nil)
    }

    /// the user's own Send/Recv (and the sync after a new password or sign-in): it goes whatever the account's state
    func sync(_ account: Int64) { pe_sync(handle, account) }

    func syncAll() {
        accounts().forEach { sync($0.id) }
    }

    /// the 10-minute timer's sync: an account whose sign-in was refused is left alone for a while (the core's back-off)
    func syncScheduled() {
        accounts().forEach { pe_sync_scheduled(handle, $0.id) }
    }

    // ---- whether each account is signed in and can connect ----

    /// what `account` shows of its sign-in and connection, in the core's words
    func accountStatus(_ account: Int64) -> AccountStatus {
        let status = pe_account_status(handle, account)
        defer { pe_account_status_free(status) }
        return AccountStatus(status)
    }

    /// the state of `account` alone, without its words: for the menus
    func accountState(_ account: Int64) -> PeAccountState { pe_account_state(handle, account) }

    /// the status bar's words for every account in place of "Done" (nil while all are connected), and how many
    /// accounts need a sign-in (the Dock's "!")
    var accountsSummary: (text: String?, needing: UInt32) {
        var needing: UInt32 = 0
        let text = taken(pe_accounts_summary(handle, &needing))
        return (text, needing)
    }

    /// the status bar's words for every account, nil while all are connected
    var accountsStatusText: String? { taken(pe_accounts_status_text(handle)) }

    /// the account the bar over the list of a tree row's `list` (with `folder`) speaks for, 0 for no bar
    func statusAccount(list: PeTreeList, folder: Int64) -> Int64 { pe_status_account_for(handle, list, folder) }

    var inboxUnread: UInt64 { pe_inbox_unread(handle) }
    /// the messages the Flagged folder lists
    var flaggedCount: UInt64 { pe_flagged_count(handle) }


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

    /// whether something was written to the store since the list was last counted: read again, it might show
    /// something else
    func stale(_ view: ListView) -> Bool {
        pe_list_view_stale(handle, view.handle)
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

    func messages(_ view: ListView, offset: UInt64, limit: UInt64) -> [Message] {
        messages(of: pe_list_view_messages(handle, view.handle, offset, limit))
    }

    /// the rows of a message list the core handed over, which is freed
    private func messages(of list: OpaquePointer?) -> [Message] {
        guard let list else { return [] }
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

    // ---- off the window thread ----

    /// the list `view` shows read on a store connection of the core's own: `ListReady` follows with the request this
    /// returns. The load selects again what `selection` has (nil for nothing): one message found nearest `hint` (the
    /// row it had, -1 when not known), several, or Select All while it is still the whole list; in its place the row
    /// `after` a removal (-1 for none), or what Undo brought back (`restored`). 0 on failure
    /// `arrived`: another row of the tree chosen, nothing selected: the message the list showed when it was left is
    /// selected, else its newest (`PE_RESELECTION_ARRIVED`)
    func load(_ view: ListView, selection: OpaquePointer?, hint: Int = -1, after: Int = -1, restored: Bool,
              arrived: Bool = false) -> UInt64 {
        pe_list_view_load(handle, view.handle, selection, Int64(hint), Int64(after), restored, arrived)
    }

    /// the message the list `view` shows in the reading pane, for the list to open with it when it is come back to
    func listShown(_ view: ListView, folder: Int64, uid: UInt64) {
        pe_list_view_shown(handle, view.handle, folder, uid)
    }

    /// the row of the folder tree the user chose (its key), for the app to start with it next time
    func treeChosen(_ key: String) {
        key.withCString { pe_tree_chosen(handle, $0) }
    }

    /// the key of the row of the folder tree chosen when the app was closed, nil when none was
    func treeStart() -> String? {
        guard let key = pe_tree_start(handle) else { return nil }
        defer { pe_string_free(key) }
        return String(cString: key)
    }

    /// a page of the list from `offset` on read the same way: `ListPageReady` follows. 0 on failure
    func loadPage(_ view: ListView, offset: UInt64) -> UInt64 {
        pe_list_view_load_page(handle, view.handle, offset)
    }

    /// what the load `request` read, after its event, taken once; nil when unknown. The selection it selects is put
    /// into `selection`, when given
    func loadResult(_ request: UInt64, selection: OpaquePointer? = nil) -> ListLoad? {
        guard let load = pe_list_load_result(handle, request) else { return nil }
        defer { pe_list_load_free(load) }
        guard let info = pe_list_load_info(load)?.pointee else { return nil }
        if info.failed {
            return .failed(taken(pe_list_load_error(load)) ?? "")
        }
        if let selection {
            _ = pe_list_load_selection(load, selection)
        }
        var selected = IndexSet()
        if let rows = pe_list_load_selected(load) {
            defer { pe_positions_free(rows) }
            selected = IndexSet((0..<pe_positions_count(rows)).map { Int(pe_positions_get(rows, $0)) })
        }
        return .read(ListRows(offset: info.offset, total: info.total, unread: info.unread, rows: info.rows,
                              listsRecipients: info.lists_recipients, reselection: info.reselection,
                              selected: selected, focus: Int(info.focus), messages: messages(of: pe_list_load_messages(load))))
    }

    /// `action` on the messages of `selection` off the window thread: `Acted` follows with the request this returns
    /// (what the status bar says, or why not), `ActionUndone` when the server refuses it. 0 on failure
    func actStart(_ selection: OpaquePointer, _ action: PeAction, to: Int64 = 0) -> UInt64 {
        pe_selection_act_start(handle, selection, action, to)
    }

    var unindexedCount: UInt64 { pe_search_unindexed_count(handle) }

    static func searchPlace(_ text: String) -> String {
        text.withCString { taken(pe_search_place($0)) } ?? ""
    }
}

// ---- encryption keys ----

/// An OpenPGP key as the windows show it, the core's words and decisions
struct PgpKey {
    let fingerprint: String
    /// in groups of four, for comparing
    let grouped: String
    let userIds: [String]
    let addresses: [String]
    /// every address it holds is verified
    let verified: Bool
    /// the user's own, with its private part
    let own: Bool
    let state: PeKeyState
    /// "Valid", "Valid until 3 May 2027", "Revoked: key compromised"
    let stateText: String
    let created: Int64
    /// 0 when it does not expire
    let expires: Int64
    let algorithm: String
    let source: String
    /// what it is called, the Status column's words, how a choice of keys names it: the core's
    let name: String
    let status: String
    let choice: String
    /// the grouped fingerprint on two lines, to read out
    let fingerprintLines: String
    let canBackUp: Bool
    let canVerify: Bool
    /// each address, a contact's with whether it is verified
    let addressLines: String
    let removeQuestion: String
    /// what Publish asks first, naming the key's addresses; empty for a contact's key
    let publishQuestion: String
    /// what They Match marks: every address of the key
    let verifyMarks: String
    let createdText: String
    let expiresText: String

    init(_ key: PeKey) {
        fingerprint = text(key.fingerprint)
        grouped = text(key.grouped)
        userIds = text(key.user_ids).split(separator: "\n").map(String.init)
        addresses = text(key.addresses).split(separator: "\n").map(String.init)
        verified = key.verified
        own = key.own
        state = key.state
        stateText = text(key.state_text)
        created = key.created
        expires = key.expires
        algorithm = text(key.algorithm)
        source = text(key.source)
        name = text(key.name)
        status = text(key.status)
        choice = text(key.choice)
        fingerprintLines = text(key.fingerprint_lines)
        canBackUp = key.can_back_up
        canVerify = key.can_verify
        addressLines = text(key.address_lines)
        removeQuestion = text(key.remove_question)
        publishQuestion = text(key.publish_question)
        verifyMarks = text(key.verify_marks)
        createdText = text(key.created_text)
        expiresText = text(key.expires_text)
    }
}

extension Core {
    /// every key, own keys first
    func pgpKeys() -> [PgpKey] {
        keyRows(pe_pgp_keys(handle))
    }

    func pgpKey(_ fingerprint: String) -> PgpKey? {
        keyRows(fingerprint.withCString { pe_pgp_key(handle, $0) }).first
    }

    private func keyRows(_ list: OpaquePointer?) -> [PgpKey] {
        guard let list else { return [] }
        defer { pe_pgp_key_list_free(list) }
        return (0..<pe_pgp_key_list_count(list)).compactMap { pe_pgp_key_list_get(list, $0).map { PgpKey($0.pointee) } }
    }

    /// false when passwords are kept in memory only: a private key made now is gone after a restart
    var privateKeysKept: Bool { pe_pgp_private_keys_kept(handle) }

    /// a new key for the account and its other addresses: its fingerprint, or why not
    func pgpGenerate(_ account: Int64) -> Result<String, Refusal> {
        var error: UnsafeMutablePointer<CChar>?
        if let fingerprint = taken(pe_pgp_generate(handle, account, &error)) {
            return .success(fingerprint)
        }
        return .failure(Refusal(taken(error) ?? Text.uiUnknownReason.text))
    }

    /// the keys of a file's bytes (or the clipboard's text, `source` PASTE) imported, private ones unlocked with
    /// `passphrase`; how it ended and the core's words
    func pgpImport(_ data: Data, passphrase: String?, source: PeKeySource = PE_KEY_SOURCE_FILE)
        -> (outcome: PeImportOutcome, message: String) {
        var message: UnsafeMutablePointer<CChar>?
        let strings = CStrings()
        defer { strings.wipe() }
        let outcome = data.withUnsafeBytes { bytes in
            pe_pgp_import(handle, bytes.bindMemory(to: UInt8.self).baseAddress, data.count, passphrase.map(strings.add),
                          source, &message)
        }
        return (outcome, taken(message) ?? "")
    }

    /// Import Key on attachment `index` of a message of the store, or (`file`) of a message file a window shows:
    /// public keys only, never a passphrase asked. Reads (and decrypts) the message on the calling thread.
    func pgpImportAttachment(folder: Int64, uid: UInt64, file: String?, index: Int) -> (outcome: PeImportOutcome, message: String) {
        var message: UnsafeMutablePointer<CChar>?
        let strings = CStrings()
        let outcome = pe_pgp_import_attachment(handle, file.map(strings.add), folder, uid, index, &message)
        return (outcome, taken(message) ?? "")
    }

    /// Publish: the own key's public part uploaded to keys.openpgp.org; KeyPublished follows with the request, 0 when
    /// it could not start
    func pgpPublish(_ fingerprint: String) -> UInt64 {
        fingerprint.withCString { pe_pgp_publish(handle, $0) }
    }

    /// what a publish did, after its KeyPublished: the words, and false for a failure; nil for another's request
    func pgpPublishResult(_ request: UInt64) -> (text: String, ok: Bool)? {
        var ok = false
        return taken(pe_pgp_publish_result(handle, request, &ok)).map { ($0, ok) }
    }

    /// Find Key on the label of a part signed by a key not known here (the link clicked): KeysFound follows with the
    /// request, 0 when it could not start
    func pgpFindHandle(_ link: String) -> UInt64 {
        link.withCString { pe_pgp_find_handle(handle, $0) }
    }

    /// Find Key in a contact's window: the keys of the card's addresses looked up; 0 when there is nothing to ask
    func contactFindKeys(_ card: Int64) -> UInt64 {
        pe_contact_find_keys(handle, card)
    }

    /// whether a contact's Find Key has anything to ask now: the window enables it by this
    func contactCanFindKeys(_ card: Int64) -> Bool {
        pe_contact_can_find_keys(handle, card)
    }

    /// what a lookup this window started found, after its KeysFound (the keys taken in now): the words to show
    func pgpFindResult(_ request: UInt64) -> String? {
        taken(pe_pgp_find_result(handle, request))
    }

    /// the public key, armored
    func pgpExport(_ fingerprint: String) -> String? {
        fingerprint.withCString { taken(pe_pgp_export(handle, $0)) }
    }

    /// the private key protected by `passphrase`, armored, or why not
    func pgpBackup(_ fingerprint: String, passphrase: String) -> Result<String, Refusal> {
        let strings = CStrings()
        defer { strings.wipe() }
        var error: UnsafeMutablePointer<CChar>?
        if let armored = fingerprint.withCString({ taken(pe_pgp_backup(handle, $0, strings.add(passphrase), &error)) }) {
            return .success(armored)
        }
        return .failure(Refusal(taken(error) ?? Text.uiUnknownReason.text))
    }

    /// the name a key is saved under: public, or a backup of the private key
    func pgpFileName(_ fingerprint: String, private: Bool) -> String {
        fingerprint.withCString { taken(pe_pgp_file_name(handle, $0, `private`)) } ?? ""
    }

    @discardableResult
    func pgpRemove(_ fingerprint: String) -> Bool {
        fingerprint.withCString { pe_pgp_remove(handle, $0) }
    }

    /// every address of the key marked as compared with its owner, or not
    func pgpSetKeyVerified(_ fingerprint: String, _ verified: Bool) {
        _ = fingerprint.withCString { pe_pgp_set_key_verified(handle, $0, verified) }
    }

    /// the key in use for a correspondent's address, and a newer one waiting for the user's decision
    func pgpPeer(_ address: String) -> (inUse: String?, pending: String?, pendingText: String) {
        guard let peer = address.withCString({ pe_pgp_peer(handle, $0) }) else { return (nil, nil, "") }
        defer { pe_pgp_peer_free(peer) }
        let some = { (pointer: UnsafeMutablePointer<CChar>?) in pointer.map { String(cString: $0) } }
        return (some(peer.pointee.in_use), some(peer.pointee.pending), some(peer.pointee.pending_text) ?? "")
    }

    /// the user's decision about the key waiting for `address`
    func pgpDecide(_ address: String, useNew: Bool) {
        _ = address.withCString { pe_pgp_decide(handle, $0, useNew) }
    }

    /// "Use this key for ...?" when own addresses an own key holds use no key yet, nil when none
    func pgpUnclaimedQuestion() -> String? {
        taken(pe_pgp_unclaimed_question(handle))
    }

    /// the answer Use It: those addresses use their keys
    func pgpClaimUnclaimed() {
        _ = pe_pgp_claim_unclaimed(handle)
    }

    /// the key of each own address that has one
    func pgpIdentities() -> [(address: String, fingerprint: String, autocrypt: Bool)] {
        guard let list = pe_pgp_identities(handle) else { return [] }
        defer { pe_pgp_identity_list_free(list) }
        return (0..<pe_pgp_identity_list_count(list)).compactMap { index in
            pe_pgp_identity_list_get(list, index).map { (text($0.pointee.address), text($0.pointee.fingerprint), $0.pointee.autocrypt) }
        }
    }

    /// the fingerprint of an account's key (nil for none) and whether its mail carries it
    func pgpAccountKey(_ account: Int64) -> (fingerprint: String?, autocrypt: Bool) {
        var autocrypt = true
        let fingerprint = taken(pe_pgp_account_key(handle, account, &autocrypt))
        return (fingerprint, autocrypt)
    }

    /// the key of an account's address and of its other ones without a key of their own; "" takes it away
    func pgpSetAccountKey(_ account: Int64, fingerprint: String, autocrypt: Bool) {
        _ = fingerprint.withCString { pe_pgp_set_account_key(handle, account, $0, autocrypt) }
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

    /// the word of a button that opens a window, with the Mac's ellipsis ("New Key…")
    var opens: String {
        text.replacingOccurrences(of: "...", with: "\u{2026}")
    }
}

/// a field's label ("Picture:", "Image :") as a title or a word in a sentence, without its colon
func fieldTitle(_ label: String) -> String {
    label.withCString { taken(pe_field_title($0)) } ?? label
}

/// What a list load read (`Core.loadResult`), or why it could not, for the status bar
enum ListLoad {
    case read(ListRows)
    case failed(String)
}

/// The rows a list load read: the counts of the status bar and the row count (for a load of the whole list), the rows
/// from `offset` on, and the rows it selects (`reselection` says how, `focus` the row to scroll to, -1 for none)
struct ListRows {
    let offset: UInt64
    let total: UInt64
    let unread: UInt64
    let rows: UInt64
    let listsRecipients: Bool
    let reselection: PeReselection
    let selected: IndexSet
    let focus: Int
    let messages: [Message]
}

/// The reads and actions windows started off the window thread, each finished by its event (`ReadDone`, `Acted`, with
/// the request in `uid`); what a window still waits for is dropped when it closes. The status bar says "Loading..."
/// for a read the user waits for that takes longer than a moment.
@MainActor
enum Pending {
    private struct Key: Hashable {
        let kind: UInt32
        let request: UInt64
    }

    private static var requests: [Key: (owner: ObjectIdentifier, done: (CoreEvent) -> Void)] = [:]

    /// `done` once the read `request` (`ReadDone`) is done; false for a request of 0 (the start failed)
    @discardableResult
    static func read(_ request: UInt64, by owner: AnyObject, _ done: @escaping () -> Void) -> Bool {
        wait(PE_EVENT_KIND_READ_DONE, request, by: owner) { _ in done() }
    }

    /// `done` with the event once the action `request` (`Acted`) is done; false for a request of 0
    @discardableResult
    static func acted(_ request: UInt64, by owner: AnyObject, _ done: @escaping (CoreEvent) -> Void) -> Bool {
        wait(PE_EVENT_KIND_ACTED, request, by: owner, done)
    }

    private static func wait(_ kind: PeEventKind, _ request: UInt64, by owner: AnyObject,
                             _ done: @escaping (CoreEvent) -> Void) -> Bool {
        guard request != 0 else { return false }
        requests[Key(kind: kind.rawValue, request: request)] = (ObjectIdentifier(owner), done)
        return true
    }

    /// a `ReadDone` or `Acted`: what waited for it done
    static func finish(_ event: CoreEvent) {
        requests.removeValue(forKey: Key(kind: event.kind.rawValue, request: event.uid))?.done(event)
    }

    /// what `owner` waits for dropped (its window closed): the reads cancelled in the core; the actions run on, as
    /// the user asked for them, unheard
    static func cancel(by owner: AnyObject, core: Core) {
        let id = ObjectIdentifier(owner)
        for (key, waiting) in requests where waiting.owner == id {
            requests.removeValue(forKey: key)
            if key.kind == PE_EVENT_KIND_READ_DONE.rawValue {
                pe_read_cancel(core.handle, key.request)
            }
        }
    }

    /// "Loading..." in the status bar (`status`) once a read takes longer than a moment, taken away when it is done
    static func busy(_ status: @escaping (String) -> Void) -> () -> Void {
        var said = false
        let timer = after(Mailbox.loadingWait) {
            said = true
            status(Text.macLoadingList.text)
        }
        return {
            timer.invalidate()
            if said { status("") }
        }
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

    /// the list of a row of the folder tree (its `list` and `folder`): a folder's, All Inboxes', All Sent's, All
    /// Drafts', Flagged's or none; false when it was shown already
    @discardableResult
    func setList(_ list: PeTreeList, folder: Int64) -> Bool {
        pe_list_view_set_list(handle, list, folder)
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

    /// Conversation order: an expanded conversation's other messages newest first
    func setNewestFirst(_ newestFirst: Bool) {
        pe_list_view_set_newest_first(handle, newestFirst)
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
    /// one folder of every account (All Inboxes, All Sent, All Drafts, no words): the place column is Account and names
    /// the account alone, and a message shown from elsewhere that is in it stays in it
    var gathersAccounts: Bool { pe_list_view_gathers_accounts(handle) }
    /// the folder of a one-folder list without words (Empty Folder, Import Messages, files dropped on it), else 0
    var ownFolder: Int64 { pe_list_view_own_folder(handle) }
    /// Mark All Read applies: a folder's list or All Inboxes, without words
    var marksAllRead: Bool { pe_list_view_marks_all_read(handle) }
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

/// Whether an account is signed in and can connect (`pe_account_status`), with everything the windows show for it in
/// the core's words; every string empty while it is connected
struct AccountStatus {
    let state: PeAccountState
    let reason: PeSignInReason
    /// what the bar's button, the mark and Sign In Again do
    let action: PeStatusAction
    /// the one dialog of the state, when `AccountStateChanged` comes with a count of 1
    let prompt: PePrompt
    /// Sign In Again applies: a sign-in the user can give
    let canSignInAgain: Bool
    let mark: PeAccountMark
    let tooltip: String
    /// the bar over the list of its folders, and its button (empty: none)
    let bar: String
    let button: String
    let notificationTitle: String
    let notificationText: String
    let composeNote: String
    let adminLink: String
    let helpTopic: String
    /// under the password field of the password dialog
    let passwordHint: String

    init(_ status: PeAccountStatus) {
        state = status.state
        reason = status.reason
        action = status.action
        prompt = status.prompt
        canSignInAgain = status.can_sign_in_again
        mark = status.mark
        tooltip = text(status.tooltip)
        bar = text(status.bar)
        button = text(status.button)
        notificationTitle = text(status.notification_title)
        notificationText = text(status.notification_text)
        composeNote = text(status.compose_note)
        adminLink = text(status.admin_link)
        helpTopic = text(status.help_topic)
        passwordHint = text(status.password_hint)
    }

    var connected: Bool { state == PE_ACCOUNT_STATE_CONNECTED }
    var needsSignIn: Bool { state == PE_ACCOUNT_STATE_SIGN_IN_NEEDED }
}

/// A row of the folder list (`pe_folder_tree`): what it is, what it says and what it allows
struct TreeRow {
    let kind: PeTreeRowKind
    /// what it stands for, the same from one reading to the next (`inboxes`, `sent`, `drafts`, `flagged`,
    /// `account:<id>`, `folder:<id>`)
    let key: String
    /// 0 for All Inboxes and Flagged
    let account: Int64
    /// 0 for All Inboxes, Flagged and an account's heading
    let folder: Int64
    let depth: Int
    let label: String
    /// what the folder bar, the window's title and a screen reader say for it ("Inbox - Gmail")
    let title: String
    /// its own unread messages (Flagged: how many are flagged)
    let unread: UInt64
    /// the count it shows while open, and while collapsed (with the rows under it)
    let countOpen: UInt64
    let countCollapsed: UInt64
    let boldOpen: Bool
    let boldCollapsed: Bool
    let parent: Bool
    let selectable: Bool
    let dropTarget: Bool
    let reordersAccounts: Bool
    /// Its menu ends with Account Properties
    let accountProperties: Bool
    let menu: PeTreeMenu
    /// what it lists when chosen (`ListView.setList` with it and `folder`)
    let list: PeTreeList
    /// with rows under it: whether it starts open, and whether the user's opening and closing of it is kept (by `key`)
    let startsOpen: Bool
    let remembersOpen: Bool
    /// where New Folder makes a folder with it chosen: the account (0: New Folder does not apply) and the folder (0:
    /// the account's top)
    let newFolderAccount: Int64
    let newFolderParent: Int64
    /// its icon's word (`Icons.treeIcon`)
    let icon: String
    /// the sign-in state of its account on the rows that stand for it (its heading, its Inbox under All Inboxes, the
    /// only account's Inbox), and what the mark's tooltip says
    let mark: PeAccountMark
    let markTooltip: String

    init(_ row: PeTreeRow) {
        kind = row.kind
        key = text(row.key)
        account = row.account
        folder = row.folder
        depth = Int(row.depth)
        label = text(row.label)
        title = text(row.title)
        unread = row.unread
        countOpen = row.count
        countCollapsed = row.count_collapsed
        boldOpen = row.bold
        boldCollapsed = row.bold_collapsed
        parent = row.parent
        selectable = row.selectable
        dropTarget = row.drop_target
        reordersAccounts = row.reorders_accounts
        accountProperties = row.account_properties
        menu = row.menu
        list = row.list
        startsOpen = row.starts_open
        remembersOpen = row.remembers_open
        newFolderAccount = row.new_folder_account
        newFolderParent = row.new_folder_parent
        icon = text(row.icon)
        mark = row.mark
        markTooltip = text(row.mark_tooltip)
    }

    func count(collapsed: Bool) -> UInt64 { collapsed ? countCollapsed : countOpen }

    func bold(collapsed: Bool) -> Bool { collapsed ? boldCollapsed : boldOpen }

    /// what the row draws: an update in place is needed when it changes
    func drawsLike(_ other: TreeRow) -> Bool {
        label == other.label && title == other.title && countOpen == other.countOpen
            && countCollapsed == other.countCollapsed && boldOpen == other.boldOpen && boldCollapsed == other.boldCollapsed
            && mark == other.mark && markTooltip == other.markTooltip
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
    /// encrypted or signed as a whole, from its structure (the list's lock or rosette)
    let protection: PeProtection
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
    /// what the row says after its subject when it opens and closes its conversation: "(3, 1 new)"; empty otherwise
    let threadLabel: String
    /// the message selecting the row opens: a collapsed conversation's oldest unread, else its newest; else its own
    let openFolder: Int64
    let openUid: UInt64
    /// with Show the whole conversation on, the row shows its conversation in the reading pane
    let showsConversation: Bool
    /// a notice that a message was not delivered, or not yet: its mark in the attachment column's place
    let bounce: Bool
    /// its conversation watched (the Watch column's glasses) or ignored (the Watch column's sign)
    let mark: PeThreadMark
    /// the row grey, its conversation ignored (the core decides)
    let dimmed: Bool
    /// the first words of what the sender wrote, empty until the core has read them (text from the sender: shown as
    /// text only)
    let snippet: String
    /// `snippet` says the message's state ("Encrypted message"), not words its sender wrote: styled as a state
    let snippetIsState: Bool
    /// what the lock or the rosette says (its tooltip, and the row's words for a screen reader), the core's; nil for
    /// neither
    let protectionWords: String?
    /// the sender's picture in the column layout: the key the core draws it by (0 for none: a logo or a contact's
    /// picture are drawn alike), and the initials shown without one
    let picture: UInt64
    let initials: String
    /// its emoji reactions' badge after the subject, the core's ("👍❤️ 3"; a collapsed conversation's are its
    /// messages'); empty for none
    let reactions: String

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
        protection = message.protection
        thread = message.thread
        threadDepth = message.thread_depth
        threadCount = message.thread_count
        threadUnread = message.thread_unread
        threadExpanded = message.thread_expanded
        bold = message.bold
        opens = message.thread_opens
        collapsed = message.thread_collapsed
        threadLabel = text(message.thread_label)
        openFolder = message.open_folder
        openUid = message.open_uid
        showsConversation = message.shows_conversation
        bounce = message.bounce
        mark = message.mark
        dimmed = message.dimmed
        snippet = text(message.snippet)
        snippetIsState = message.snippet_is_state
        let words = text(message.protection_words)
        protectionWords = words.isEmpty ? nil : words
        picture = message.picture
        initials = text(message.initials)
        reactions = text(message.reactions)
    }
}

/// A message view of the core: the header, the sanitized document, the attachments; freed with it
final class MessageView {
    let handle: OpaquePointer
    /// the conversation's view this one belongs to (an open message of its stack): kept alive by it, never freed by
    /// itself
    private let owner: MessageView?

    init?(_ handle: OpaquePointer?) {
        guard let handle else { return nil }
        self.handle = handle
        owner = nil
    }

    private init(borrowed handle: OpaquePointer, owner: MessageView) {
        self.handle = handle
        self.owner = owner
    }

    deinit {
        if owner == nil {
            pe_message_view_free(handle)
        }
    }

    /// the rows and frames of a conversation's stack, in order; a message shown alone has one, the core's, at 0, 0
    var entries: [ConversationEntry] {
        let count = info?.pointee.conversation_entry_count ?? 0
        return (0..<count).compactMap { pe_conversation_entry(handle, $0).map { ConversationEntry($0.pointee) } }
    }

    /// the view entry `index`'s frame shows: this one for the selected message, its own for another open one; nil for
    /// a folded message or one still downloading
    func entryView(_ index: Int) -> MessageView? {
        guard let own = pe_conversation_entry_view(handle, index) else { return nil }
        return own == handle ? self : MessageView(borrowed: own, owner: self)
    }

    var info: UnsafePointer<PeMessageInfo>? { pe_message_view_info(handle) }

    /// the document of part `index` of a signed or encrypted message, copied; nil past the end or for a part with
    /// nothing to show
    func part(_ index: Int) -> String? {
        guard index >= 0, let document = pe_message_view_part(handle, index) else { return nil }
        let copied = String(cString: document)
        return copied.isEmpty ? nil : copied
    }

    func attachment(_ index: Int) -> Attachment? {
        guard let attachment = pe_message_view_attachment(handle, index)?.pointee else { return nil }
        return Attachment(name: text(attachment.filename), size: attachment.size, sizeText: text(attachment.size_text),
                          kind: attachment.kind, canOpen: attachment.can_open, tooltip: text(attachment.tooltip),
                          refusal: text(attachment.refusal), part: Int(attachment.part),
                          protection: attachment.protection, partText: text(attachment.part_text), isKey: attachment.is_key)
    }

    /// what the strip menu's Show in Message says of file `index`: no item, checked, unchecked or greyed
    func showInMessage(_ index: Int) -> PeShowInMessage {
        pe_message_view_attachment(handle, index)?.pointee.show_in_message ?? PE_SHOW_IN_MESSAGE_NONE
    }

    /// every attached file, in order
    var attachments: [Attachment] {
        (0..<(info?.pointee.attachment_count ?? 0)).compactMap { attachment($0) }
    }
}

/// A file attached to a message, as the core describes it: its name for display, its size in bytes and in words, its
/// kind (its icon), whether it may be opened from the message, the strip's tooltip and what is said when a file that
/// may not be opened is (empty for one that may); in a message with signed or encrypted parts, the part it came from
/// (from 1, 0 in any other message), how that part was protected (the strip's lock for an encrypted one) and the
/// core's line that says so, which ends the tooltip too
struct Attachment: Equatable {
    let name: String
    let size: UInt64
    let sizeText: String
    let kind: PeFileKind
    let canOpen: Bool
    let tooltip: String
    let refusal: String
    var part = 0
    var protection = PE_PROTECTION_NONE
    var partText = ""
    /// it holds OpenPGP public keys: its menu offers Import Key
    var isKey = false
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

    /// the line a draft an AI agent wrote shows in the compose window, the core's words; nil for the user's own
    var agentNote: String? { info?.pointee.agent_note.map { String(cString: $0) } }
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

/// A date formatter made once: `setUp` gives it its style
@MainActor
private func formatter(_ setUp: (DateFormatter) -> Void) -> DateFormatter {
    let formatter = DateFormatter()
    setUp(formatter)
    return formatter
}

@MainActor private let dateAndTime = formatter { $0.dateStyle = .short; $0.timeStyle = .short }

/// A date as the user's settings write it, short date and time
@MainActor
func formatDate(_ seconds: Int64) -> String {
    dateAndTime.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
}

/// What the column list's dates are seen from: now and the time zone's offset, taken once for a page of rows
struct DateClock {
    let now: Int64
    let offset: Int64

    init() {
        let date = Date()
        now = Int64(date.timeIntervalSince1970)
        offset = Int64(TimeZone.current.secondsFromGMT(for: date))
    }
}

/// the formats of the column list's dates, one each of PeDateStyle's
@MainActor private let shortFormats: [UInt32: DateFormatter] = [
    PE_DATE_STYLE_TIME.rawValue: formatter { $0.timeStyle = .short },
    PE_DATE_STYLE_WEEKDAY.rawValue: formatter { $0.setLocalizedDateFormatFromTemplate("EEEE") },
    PE_DATE_STYLE_DAY_MONTH.rawValue: formatter { $0.setLocalizedDateFormatFromTemplate("dMMM") },
    PE_DATE_STYLE_FULL.rawValue: formatter { $0.dateStyle = .short },
]

/// A date of the column list's rows, short as the core says for its age seen at `clock`: the time today, the weekday
/// this week, the day and month this year, the date before
@MainActor
func shortDate(_ seconds: Int64, at clock: DateClock) -> String {
    let style = pe_date_style(seconds, clock.now, clock.offset)
    let formatter = shortFormats[style.rawValue] ?? dateAndTime
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
