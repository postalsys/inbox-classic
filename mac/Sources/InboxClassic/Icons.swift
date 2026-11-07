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

    /// The colour of a flag as Apple Mail shows it (1 red to 7 gray, PeMessage.flag_color), the system's palette
    static func flagColor(_ color: UInt8) -> NSColor {
        switch color {
        case 2: return .systemOrange
        case 3: return .systemYellow
        case 4: return .systemGreen
        case 5: return .systemBlue
        case 6: return .systemPurple
        case 7: return .systemGray
        default: return .systemRed
        }
    }

    /// A flag filled in its colour, for the list and the Flag menu: not a template, so it keeps its colour on a
    /// selected row
    static func coloredFlag(_ color: UInt8) -> NSImage? { flagImage(flagColor(color), key: "flag.fill@\(color)") }

    /// A flag on a selected row: white, whatever its colour
    static var selectedFlag: NSImage? { flagImage(.white, key: "flag.fill@white") }

    private static func flagImage(_ color: NSColor, key: String) -> NSImage? {
        symbol("flag.fill", key: key, colors: [color])
    }

    /// The mark of a delivery notice (a bounce) in the list: an outlined exclamation mark in a circle, a template
    /// drawn in the paper clip's colour (white on a selected row, as the clip is); the card says how bad it is
    static var bounce: NSImage? { symbol("exclamationmark.circle", key: "bounce", template: true) }

    /// The Watch column's mark of a conversation: glasses while it is watched, a muted speaker while it is
    /// ignored; templates drawn in the paper clip's colour (white on a selected row)
    static func threadMark(_ mark: PeThreadMark) -> NSImage? {
        switch mark {
        case PE_THREAD_MARK_WATCH: return symbol("eyeglasses", key: "watch", template: true)
        case PE_THREAD_MARK_IGNORE: return symbol("speaker.slash", key: "ignore", template: true)
        default: return nil
        }
    }

    /// the glasses over the Watch column, as the paper clip and the flag are over theirs
    static var watchHeader: NSImage? { threadMark(PE_THREAD_MARK_WATCH) }

    /// A system symbol at the list's size, cached under `key`: a template the cell tints, or drawn in `colors`
    private static func symbol(_ name: String, key: String, colors: [NSColor] = [], template: Bool = false) -> NSImage? {
        if let image = cache[key] { return image }
        var config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        if !colors.isEmpty {
            config = config.applying(NSImage.SymbolConfiguration(paletteColors: colors))
        }
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }
        image.isTemplate = template
        cache[key] = image
        return image
    }

    /// `image` drawn in `color`: a template icon where its cell does not tint it (a column header)
    static func tinted(_ image: NSImage, _ color: NSColor) -> NSImage {
        NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
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
