// The senders' pictures of the column layout's rows: the pixels the core draws (a brand's logo), kept for the run by
// their key and size so fifty rows from one sender cost one request, and the round view a row shows them in, or the
// sender's initials while there is no picture.
import AppKit
import CInboxClassic

/// The core's pixels (`side` x `side`, BGRA with the alpha multiplied in) as an image `points` wide; nil for anything
/// else
func pixelImage(_ pixels: Data?, side: Int, points: CGFloat) -> NSImage? {
    guard let pixels, side > 0, pixels.count == side * side * 4, let provider = CGDataProvider(data: pixels as CFData),
          let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue
                                  | CGImageAlphaInfo.premultipliedFirst.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    else { return nil }
    return NSImage(cgImage: image, size: NSSize(width: points, height: points))
}

/// The pictures of the list's rows, asked of the core once a key and size, kept for the run
@MainActor
final class ListPictures {
    private struct Key: Hashable {
        let picture: UInt64
        let pixels: Int
    }

    private let core: Core
    private var images: [Key: NSImage] = [:]
    /// asked for and not drawn yet (or drawn as nothing): not asked again
    private var asked: Set<Key> = []
    private var requests: [UInt64: Key] = [:]
    /// a picture arrived: the rows with its key are drawn again
    var arrived: (UInt64) -> Void = { _ in }

    init(core: Core) {
        self.core = core
    }

    /// The picture of `picture` drawn `points` wide at `scale`; nil while it is being drawn, or when there is none
    func image(_ picture: UInt64, points: CGFloat, scale: CGFloat) -> NSImage? {
        guard picture != 0 else { return nil }
        let key = Key(picture: picture, pixels: Int((points * scale).rounded()))
        if let image = images[key] {
            return image
        }
        if asked.insert(key).inserted {
            let request = pe_picture_start(core.handle, picture, UInt32(key.pixels))
            if request != 0 {
                requests[request] = key
            }
        }
        return nil
    }

    /// PictureReady: its pixels kept and the rows told; true when it was one of these
    func ready(_ request: UInt64, points: CGFloat) -> Bool {
        guard let key = requests.removeValue(forKey: request) else { return false }
        var length = 0
        if let image = pixelImage(takenBytes(pe_picture_result(core.handle, request, &length), length), side: key.pixels,
                                  points: points) {
            images[key] = image
            arrived(key.picture)
        }
        return true
    }
}

/// A sender's picture in a row: round, the picture when there is one, else the initials on a quiet fill, one tone for
/// everyone. Decorative: the row's label says who it is
final class SenderPicture: NSView {
    static let size: CGFloat = 32

    var image: NSImage? { didSet { needsDisplay = true } }
    var initials = "" { didSet { needsDisplay = true } }
    /// on the selection's colour: white initials on a light veil
    var onSelection = false { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    override func isAccessibilityElement() -> Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let circle = NSBezierPath(ovalIn: bounds)
        if let image {
            NSGraphicsContext.saveGraphicsState()
            circle.addClip()
            // a logo on white, as brands draw them for a light background
            NSColor.white.setFill()
            circle.fill()
            image.draw(in: bounds)
            NSGraphicsContext.restoreGraphicsState()
            NSColor.separatorColor.setStroke()
            circle.lineWidth = 0.5
            circle.stroke()
            return
        }
        (onSelection ? NSColor.white.withAlphaComponent(0.22) : NSColor.quaternaryLabelColor).setFill()
        circle.fill()
        guard !initials.isEmpty else { return }
        let color: NSColor = onSelection ? .alternateSelectedControlTextColor : .secondaryLabelColor
        let text = NSAttributedString(string: initials, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: color,
        ])
        let size = text.size()
        text.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
    }
}
