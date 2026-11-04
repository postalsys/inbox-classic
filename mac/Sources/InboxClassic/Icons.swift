// The icons: the Fluent UI System Icons of app/res/icons, which scripts/mac-build.sh turns into PDFs in the app's
// Resources/icons, drawn as template images so they take the colors of the toolbar, the tree and the list.
import AppKit
import CInboxClassic

@MainActor
enum Icons {
    private static var cache: [String: NSImage] = [:]

    /// the folder of the app's resources: the bundle's, or where the build put them for a run from the build folder
    static var resources: URL {
        if let bundled = Bundle.main.resourceURL, FileManager.default.fileExists(atPath: bundled.appendingPathComponent("icons").path) {
            return bundled
        }
        return URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("Resources")
    }

    /// `name` at `size` points, Fluent's own small design where there is one
    private static func icon(_ name: String, size: CGFloat, small: Bool) -> NSImage? {
        let key = "\(name)@\(size)"
        if let image = cache[key] { return image }
        let folder = resources.appendingPathComponent("icons")
        let candidates = small ? ["\(name)_16", "\(name)_20", name] : [name, "\(name)_20"]
        guard let file = candidates.map({ folder.appendingPathComponent("\($0).pdf") })
            .first(where: { FileManager.default.fileExists(atPath: $0.path) }),
            let image = NSImage(contentsOf: file) else { return nil }
        image.size = NSSize(width: size, height: size)
        image.isTemplate = true
        cache[key] = image
        return image
    }

    static func toolbar(_ name: String) -> NSImage? { icon(name, size: 20, small: false) }
    static func list(_ name: String) -> NSImage? { icon(name, size: 16, small: true) }
    static func folder(_ name: String) -> NSImage? { icon(name, size: 16, small: true) }
    static func format(_ name: String) -> NSImage? { icon(name, size: 16, small: true) }

    /// the icon of a folder in the tree, by what it is for
    static func folderIcon(_ use: PeSpecialUse) -> String {
        switch use {
        case PE_SPECIAL_USE_INBOX: return "mail_inbox"
        case PE_SPECIAL_USE_SENT: return "send"
        case PE_SPECIAL_USE_DRAFTS: return "drafts"
        case PE_SPECIAL_USE_TRASH: return "delete"
        case PE_SPECIAL_USE_JUNK: return "mail_prohibited"
        case PE_SPECIAL_USE_ARCHIVE: return "archive"
        case PE_SPECIAL_USE_FLAGGED: return "flag"
        case PE_SPECIAL_USE_ALL: return "mail_multiple"
        default: return "folder"
        }
    }

    /// a picture of the resources (the providers' sign-in buttons)
    static func picture(_ name: String) -> NSImage? {
        NSImage(contentsOf: resources.appendingPathComponent(name))
    }
}
