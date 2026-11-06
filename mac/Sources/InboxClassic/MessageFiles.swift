// Messages as .eml files: dragged out of the list onto the Finder (file promises, written once the Finder says where,
// downloaded first when they are not here yet), saved several at a time, forwarded as attachments, and .eml files
// dropped onto a folder. The core names, downloads and writes them; this file hands them to the system.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

/// A value handed to a thread of its own: the core's handles may be used from any thread
struct Handed<T>: @unchecked Sendable {
    let value: T
}

/// Runs `work` on a thread of its own (the core blocks there while messages download), then `done` on the main thread
func inBackground<T>(_ work: @escaping () -> T, then done: @escaping @MainActor (T) -> Void) {
    let box = Handed(value: work)
    Thread.detachNewThread {
        let result = Handed(value: box.value())
        onMain { done(result.value) }
    }
}

/// The type of an .eml file
let emlType = UTType(filenameExtension: "eml", conformingTo: .data) ?? .data

/// How long the core may wait for messages to download for files: long enough for a slow server, not forever
let exportTimeout: UInt64 = 120_000

/// The messages of a selection, in its order
func refs(of selection: OpaquePointer) -> [(Int64, UInt64)] {
    var refs: [(Int64, UInt64)] = []
    var folder: Int64 = 0
    var uid: UInt64 = 0
    var index = 0
    while pe_selection_get(selection, index, &folder, &uid) {
        refs.append((folder, uid))
        index += 1
    }
    return refs
}

/// A selection of the core holding `refs`, freed with pe_selection_free
func newSelection(_ refs: [(Int64, UInt64)]) -> OpaquePointer {
    let selection: OpaquePointer = pe_selection_new()
    for (folder, uid) in refs {
        pe_selection_add(selection, folder, uid)
    }
    return selection
}

/// The texts of a list of the core, freed here
func takenTexts(_ list: OpaquePointer?) -> [String] {
    guard let list else { return [] }
    defer { pe_text_list_free(list) }
    return (0..<pe_text_list_count(list)).map { text(pe_text_list_get(list, $0)) }
}

/// `name` in `dir`, or `name (2).eml`, `name (3).eml`... when that is taken: a file there is never replaced
func freeURL(in dir: URL, for name: String) -> URL {
    let url = dir.appendingPathComponent(name)
    guard FileManager.default.fileExists(atPath: url.path) else { return url }
    let stem = url.deletingPathExtension().lastPathComponent
    let ext = url.pathExtension
    for n in 2... {
        let candidate = dir.appendingPathComponent(ext.isEmpty ? "\(stem) (\(n))" : "\(stem) (\(n)).\(ext)")
        if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
    }
    return url
}

/// The messages of one drag out of the list: their file names at once (the Finder asks for them as the drag starts),
/// their sources once, when the first file is to be written
final class DragExport: @unchecked Sendable {
    let refs: [(Int64, UInt64)]
    let names: [String]
    private let core: OpaquePointer
    private let lock = NSLock()
    private var files: [(data: Data?, problem: String?)]?

    init(core: OpaquePointer, refs: [(Int64, UInt64)]) {
        self.core = core
        self.refs = refs
        let selection = newSelection(refs)
        defer { pe_selection_free(selection) }
        let names = takenTexts(pe_selection_file_names(core, selection))
        self.names = names.count == refs.count ? names : refs.map { _ in "message.eml" }
    }

    /// The bytes of message `index`, or why not; the first call downloads what is missing, for all of them. Blocks.
    func file(_ index: Int) -> (data: Data?, problem: String?) {
        lock.lock()
        defer { lock.unlock() }
        if files == nil {
            let selection = newSelection(refs)
            defer { pe_selection_free(selection) }
            var got: [(data: Data?, problem: String?)] = refs.map { _ in (nil, "The message could not be downloaded.") }
            if let export = pe_selection_export(core, selection, exportTimeout) {
                defer { pe_export_free(export) }
                for i in 0..<min(pe_export_count(export), got.count) {
                    var name: UnsafePointer<CChar>?
                    var data: UnsafePointer<UInt8>?
                    var length = 0
                    var error: UnsafePointer<CChar>?
                    guard pe_export_get(export, i, &name, &data, &length, &error) else { continue }
                    if let data {
                        got[i] = (Data(bytes: data, count: length), nil)
                    } else {
                        got[i] = (nil, error.map { text($0) } ?? "The message could not be downloaded.")
                    }
                }
            }
            files = got
        }
        return files![index]
    }
}

/// A message on the drag pasteboard: a file promise for the Finder, and the message itself for the folder tree. AppKit
/// makes these with init() too (initWithFileType:delegate: calls it), so the message is set after.
final class MessagePromise: NSFilePromiseProvider {
    private(set) var drag: DragExport?
    private(set) var index = 0

    override init() {
        super.init()
    }

    convenience init(drag: DragExport, index: Int, delegate: NSFilePromiseProviderDelegate) {
        self.init()
        self.drag = drag
        self.index = index
        // a concrete type of a file (the .eml one), not the abstract public.email-message, which a promise refuses
        fileType = emlType.identifier
        self.delegate = delegate
    }

    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        super.writableTypes(for: pasteboard) + [messagePasteboardType]
    }

    override func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard)
        -> NSPasteboard.WritingOptions {
        type == messagePasteboardType ? [] : super.writingOptions(forType: type, pasteboard: pasteboard)
    }

    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        if type == messagePasteboardType, let drag {
            let (folder, uid) = drag.refs[index]
            return "\(folder) \(uid)"
        }
        return super.pasteboardPropertyList(forType: type)
    }
}

/// Writes the files the Finder was promised, on a queue of their own: downloaded when not here yet, never over a file
/// that is there, marked as from the internet
final class PromiseWriter: NSObject, NSFilePromiseProviderDelegate, @unchecked Sendable {
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()
    /// what a write said, for the status bar: the folder written to, or the problem
    var wrote: @MainActor (URL?, String?) -> Void = { _, _ in }

    func filePromiseProvider(_ provider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        guard let promise = provider as? MessagePromise, let drag = promise.drag else { return "message.eml" }
        return drag.names[promise.index]
    }

    func operationQueue(for provider: NSFilePromiseProvider) -> OperationQueue {
        queue
    }

    func filePromiseProvider(_ provider: NSFilePromiseProvider, writePromiseTo url: URL,
                             completionHandler: @escaping (Error?) -> Void) {
        guard let promise = provider as? MessagePromise, let drag = promise.drag else {
            completionHandler(CocoaError(.fileWriteUnknown))
            return
        }
        let error = write(drag, promise.index, to: url)
        completionHandler(error.map { CocoaError(.fileWriteUnknown, userInfo: [NSLocalizedDescriptionKey: $0]) })
    }

    /// Message `index` of `drag` into `url`'s folder, then what the status bar says of it; why not when it could not
    /// be. Blocks: the download and the write happen on the calling thread, only the report on the main one.
    @discardableResult
    func write(_ drag: DragExport, _ index: Int, to url: URL) -> String? {
        let file = drag.file(index)
        var error: String?
        if let data = file.data {
            let target = freeURL(in: url.deletingLastPathComponent(), for: url.lastPathComponent)
            error = writeDownloaded(data, to: target) ? nil : "The file could not be written."
        } else {
            error = file.problem ?? "The message could not be downloaded."
        }
        let wrote = Handed(value: self.wrote)
        let dir = url.deletingLastPathComponent()
        let report = error.map { "\(drag.names[index]): \($0)" }
        onMain { wrote.value(error == nil ? dir : nil, report) }
        return error
    }
}
