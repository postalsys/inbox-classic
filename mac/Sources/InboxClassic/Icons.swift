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
    static func coloredFlag(_ color: UInt8) -> NSImage? {
        let key = "flag.fill@\(color)"
        if let image = cache[key] { return image }
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [flagColor(color)]))
        guard let image = NSImage(systemSymbolName: "flag.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }
        image.isTemplate = false
        cache[key] = image
        return image
    }

    /// A flag on a selected row: white, whatever its colour
    static let selectedFlag: NSImage? = {
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
        let image = NSImage(systemSymbolName: "flag.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config)
        image?.isTemplate = false
        return image
    }()

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
