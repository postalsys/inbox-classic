// The strip of a message's attached files under its header, in the reading pane and in a message's own window (both
// are a Reader): a tile for each file with the icon of its kind, its name (shortened in the middle, the whole name in
// its tooltip) and its size, wrapping into rows and scrolling past three. A double-click, Return or Enter opens the
// file chosen; a right-click, Shift+F10 or the menu key offers Open, Save As and Save All. The core says what each file
// is, its size in words, whether it may be opened, its tooltip and what to say when it may not: a file that can run
// programs looks the same, says why in its tooltip, and is never opened.
import AppKit
import CInboxClassic

@MainActor
final class AttachmentStrip: NSView {
    /// a file to open, by its index
    var opened: (Int) -> Void = { _ in }
    /// the menu of a file, by its index
    var menuOf: (Int) -> NSMenu = { _ in NSMenu() }
    private(set) var files: [Attachment] = []
    private(set) var tiles: [AttachmentTile] = []
    private(set) var selected: Int?
    /// the menu popped up from the keyboard, while it is open
    private(set) var shownMenu: NSMenu?
    private let scroll = NSScrollView()
    private let field = FlippedView()
    private var height: NSLayoutConstraint!
    private var observers: [NSObjectProtocol] = []

    static let insets = NSEdgeInsets(top: 0, left: 10, bottom: 8, right: 10)
    static let rowHeight: CGFloat = 40
    static let gap = NSSize(width: 8, height: 6)
    /// rows shown before the strip scrolls
    static let rowsShown = 3

    override init(frame: NSRect) {
        super.init(frame: frame)
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.verticalScrollElasticity = .none
        scroll.documentView = field
        addSubview(scroll)
        height = heightAnchor.constraint(equalToConstant: 0)
        height.isActive = true
        isHidden = true
        setAccessibilityElement(true)
        setAccessibilityRole(.list)
        setAccessibilityLabel(Text.uiAttachmentsStrip.text)
        setAccessibilityIdentifier("reader.attachmentStrip")
    }

    required init?(coder: NSCoder) { fatalError() }

    /// the files of the message shown; none hides the strip
    func show(_ files: [Attachment]) {
        guard files != self.files || tiles.isEmpty != files.isEmpty else {
            isHidden = files.isEmpty
            return
        }
        self.files = files
        tiles.forEach { $0.removeFromSuperview() }
        tiles = files.enumerated().map { index, file in
            let tile = AttachmentTile(file, index: index)
            tile.strip = self
            field.addSubview(tile)
            return tile
        }
        selected = nil
        restyle()
        isHidden = files.isEmpty
        scroll.contentView.scroll(to: .zero)
        needsLayout = true
    }

    func clear() {
        show([])
    }

    /// every tile's colours again: the choice or the keyboard moved, the window became key or stopped being key
    func restyle() {
        tiles.forEach { $0.restyle() }
    }

    /// the tile of the file being opened shown busy, nil for none
    func busy(_ index: Int?) {
        for tile in tiles {
            tile.alphaValue = tile.index == index ? 0.45 : 1
        }
    }

    // ---- layout ----

    override func layout() {
        super.layout()
        let insets = Self.insets
        let width = max(bounds.width - insets.left - insets.right, 0)
        let most = CGFloat(Self.rowsShown) * Self.rowHeight + CGFloat(Self.rowsShown - 1) * Self.gap.height
        var content = arrange(width: width)
        // a scroller that takes room (a mouse without a scroll wheel) is not drawn over the last tile of a row
        if content > most && NSScroller.preferredScrollerStyle == .legacy {
            content = arrange(width: width - NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy))
        }
        let shown = min(content, most)
        let wanted = files.isEmpty ? 0 : shown + insets.top + insets.bottom
        if height.constant != wanted {
            height.constant = wanted
        }
        scroll.frame = NSRect(x: insets.left, y: insets.bottom, width: width, height: shown)
        field.frame = NSRect(x: 0, y: 0, width: scroll.contentSize.width, height: content)
    }

    /// the tiles placed in rows `width` wide; the height they take
    @discardableResult
    private func arrange(width: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        var y: CGFloat = 0
        for tile in tiles {
            let tileWidth = min(tile.wanted, width)
            if x > 0 && x + tileWidth > width {
                x = 0
                y += Self.rowHeight + Self.gap.height
            }
            tile.frame = NSRect(x: x, y: y, width: tileWidth, height: Self.rowHeight)
            x += tileWidth + Self.gap.width
        }
        return tiles.isEmpty ? 0 : y + Self.rowHeight
    }

    // ---- choosing ----

    func select(_ index: Int?) {
        let index = index.map { min(max($0, 0), files.count - 1) }
        selected = files.isEmpty ? nil : index
        restyle()
        if let selected {
            let tile = tiles[selected]
            tile.scrollToVisible(tile.bounds)
            NSAccessibility.post(element: tile, notification: .focusedUIElementChanged)
        }
    }

    /// the strip has the keyboard in the key window: the file chosen shows in the accent colour
    var focused: Bool {
        guard let window else { return false }
        return window.isKeyWindow && window.firstResponder === self
    }

    override var acceptsFirstResponder: Bool { !files.isEmpty }
    override var canBecomeKeyView: Bool { !isHidden && !files.isEmpty }

    override func becomeFirstResponder() -> Bool {
        if selected == nil && !files.isEmpty {
            select(0)
        }
        // after it took the keyboard, as `focused` asks the window
        onMain { [weak self] in self?.restyle() }
        return true
    }

    override func resignFirstResponder() -> Bool {
        onMain { [weak self] in self?.restyle() }
        return true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        guard let window else { return }
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: nil) { [weak self] _ in
                MainActor.assumeIsolated { self?.restyle() }
            })
        }
    }

    // ---- the mouse ----

    func clicked(_ tile: AttachmentTile, _ event: NSEvent) {
        window?.makeFirstResponder(self)
        select(tile.index)
        if event.clickCount == 2 {
            opened(tile.index)
        }
    }

    func menu(for tile: AttachmentTile) -> NSMenu {
        window?.makeFirstResponder(self)
        select(tile.index)
        return menuOf(tile.index)
    }

    // ---- the keyboard ----

    override func keyDown(with event: NSEvent) {
        let plain = event.modifierFlags.intersection([.command, .control, .option]).isEmpty
        guard plain, !files.isEmpty else { return super.keyDown(with: event) }
        let current = selected ?? 0
        switch event.keyCode {
        case 123: select(current - 1)
        case 124: select(current + 1)
        case 125: select(nextRow(from: current, down: true))
        case 126: select(nextRow(from: current, down: false))
        case 115: select(0)
        case 119: select(files.count - 1)
        case 36, 76: opened(current)
        // Shift+F10 and the menu key of a PC keyboard: the file's menu, as a right-click
        case 109 where event.modifierFlags.contains(.shift), 110: showMenu()
        default: super.keyDown(with: event)
        }
    }

    /// the file of the row below or above nearest across, or the same one at the end
    private func nextRow(from index: Int, down: Bool) -> Int {
        let here = tiles[index].frame
        let rows = tiles.filter { down ? $0.frame.minY > here.minY : $0.frame.minY < here.minY }
        guard let row = down ? rows.map(\.frame.minY).min() : rows.map(\.frame.minY).max() else { return index }
        return rows.filter { $0.frame.minY == row }.min { abs($0.frame.midX - here.midX) < abs($1.frame.midX - here.midX) }?.index ?? index
    }

    /// the menu of the file chosen, under it
    func showMenu() {
        guard let selected else { return }
        let tile = tiles[selected]
        let menu = menuOf(selected)
        shownMenu = menu
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: tile.bounds.maxY + 2), in: tile)
        shownMenu = nil
    }

    override func accessibilityChildren() -> [Any]? { tiles }
    override func accessibilitySelectedChildren() -> [Any]? { selected.map { [tiles[$0]] } }
}

/// One file of the strip
@MainActor
final class AttachmentTile: NSView {
    weak var strip: AttachmentStrip?
    let file: Attachment
    let index: Int
    private let icon = NSImageView()
    private let name = NSTextField(labelWithString: "")
    private let size = NSTextField(labelWithString: "")
    private var hovering = false
    /// as wide as its name or size needs, within the narrowest and widest a tile is
    let wanted: CGFloat
    /// its fill, set with its other colours when its state changes (`restyle`)
    private var fill = NSColor.clear

    private static let nameFont = NSFont.systemFont(ofSize: 12)
    private static let sizeFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    private static let iconSide: CGFloat = 24
    private static let padding: CGFloat = 8
    private static let widest: CGFloat = 220
    private static let narrowest: CGFloat = 96

    init(_ file: Attachment, index: Int) {
        self.file = file
        self.index = index
        let words = max(file.name.size(withAttributes: [.font: Self.nameFont]).width,
                        file.sizeText.size(withAttributes: [.font: Self.sizeFont]).width)
        wanted = min(max(Self.padding + Self.iconSide + 6 + ceil(words) + 4 + Self.padding, Self.narrowest), Self.widest)
        super.init(frame: .zero)
        icon.imageScaling = .scaleProportionallyDown
        name.stringValue = file.name
        name.font = Self.nameFont
        name.lineBreakMode = .byTruncatingMiddle
        name.cell?.truncatesLastVisibleLine = true
        size.stringValue = file.sizeText
        size.font = Self.sizeFont
        size.lineBreakMode = .byTruncatingTail
        for label in [name, size] {
            label.isSelectable = false
            label.refusesFirstResponder = true
        }
        [icon, name, size].forEach(addSubview)
        // the core's: the whole name and size, and why a program is not opened
        toolTip = file.tooltip
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("\(file.name), \(file.sizeText)")
        setAccessibilityHelp(file.canOpen ? nil : file.refusal)
        setAccessibilityIdentifier("reader.attachment.\(index)")
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }

    var isSelected: Bool { strip?.selected == index }

    override func layout() {
        super.layout()
        let side = Self.iconSide
        icon.frame = NSRect(x: Self.padding, y: (bounds.height - side) / 2, width: side, height: side)
        let left = icon.frame.maxX + 6
        let width = max(bounds.width - left - Self.padding, 0)
        name.frame = NSRect(x: left, y: 4, width: width, height: 16)
        size.frame = NSRect(x: left, y: 21, width: width, height: 14)
    }

    /// its colours for its state: chosen (in the accent colour while the strip has the keyboard), under the mouse, or
    /// neither; dynamic colours, which follow the appearance by themselves
    func restyle() {
        let emphasized = isSelected && strip?.focused == true
        if emphasized {
            fill = .selectedContentBackgroundColor
        } else if isSelected {
            fill = .unemphasizedSelectedContentBackgroundColor
        } else {
            fill = NSColor.labelColor.withAlphaComponent(hovering ? 0.10 : 0.055)
        }
        name.textColor = emphasized ? .alternateSelectedControlTextColor : .labelColor
        size.textColor = emphasized ? .alternateSelectedControlTextColor.withAlphaComponent(0.85) : .secondaryLabelColor
        icon.image = Self.icon(file.kind, color: emphasized ? .white : nil)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        fill.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()
    }

    override func mouseEntered(with event: NSEvent) {
        hovering = true
        restyle()
    }

    override func mouseExited(with event: NSEvent) {
        hovering = false
        restyle()
    }

    override func mouseDown(with event: NSEvent) {
        strip?.clicked(self, event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        strip?.menu(for: self)
    }

    override func accessibilityPerformPress() -> Bool {
        strip?.select(index)
        strip?.opened(index)
        return true
    }

    override func accessibilityPerformShowMenu() -> Bool {
        strip?.select(index)
        strip?.showMenu()
        return true
    }

    override func isAccessibilitySelected() -> Bool { isSelected }

    // ---- the icons ----

    /// the SF Symbol of a kind of file the core names, and its colour
    static func symbol(_ kind: PeFileKind) -> (name: String, color: NSColor) {
        switch kind {
        case PE_FILE_KIND_IMAGE: ("photo", .systemTeal)
        case PE_FILE_KIND_PDF: ("doc.richtext", .systemRed)
        case PE_FILE_KIND_DOCUMENT: ("doc.text", .systemBlue)
        case PE_FILE_KIND_SPREADSHEET: ("tablecells", .systemGreen)
        case PE_FILE_KIND_PRESENTATION: ("chart.bar.doc.horizontal", .systemOrange)
        case PE_FILE_KIND_ARCHIVE: ("archivebox", .systemBrown)
        case PE_FILE_KIND_AUDIO: ("waveform", .systemPink)
        case PE_FILE_KIND_VIDEO: ("film", .systemPurple)
        case PE_FILE_KIND_CALENDAR: ("calendar", .systemRed)
        case PE_FILE_KIND_CONTACT: ("person.crop.square", .systemGray)
        case PE_FILE_KIND_KEY: ("key", .systemIndigo)
        case PE_FILE_KIND_TEXT: ("doc.plaintext", .secondaryLabelColor)
        case PE_FILE_KIND_MAIL: ("envelope", .systemBlue)
        case PE_FILE_KIND_PROGRAM: ("gearshape", .systemGray)
        case PE_FILE_KIND_OTHER: ("doc", .secondaryLabelColor)
        default: ("doc", .secondaryLabelColor)
        }
    }

    private static var cache: [String: NSImage] = [:]

    static func icon(_ kind: PeFileKind, color: NSColor? = nil) -> NSImage? {
        let key = "\(kind.rawValue)@\(color == nil ? "own" : "white")"
        if let image = cache[key] { return image }
        let (name, own) = symbol(kind)
        let config = NSImage.SymbolConfiguration(pointSize: 19, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color ?? own]))
        let image = (NSImage(systemSymbolName: name, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "doc", accessibilityDescription: nil))?.withSymbolConfiguration(config)
        cache[key] = image
        return image
    }
}

/// A view whose first row is at its top, for the strip's rows
final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

/// `content` in a scroll `width` wide and `height` tall that scrolls up and down, laid out from its top
@MainActor
func scrolledColumn(_ content: NSView, width: CGFloat, height: CGFloat) -> NSScrollView {
    let document = FlippedView()
    document.addSubview(content)
    content.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        content.topAnchor.constraint(equalTo: document.topAnchor),
        content.leadingAnchor.constraint(equalTo: document.leadingAnchor),
        content.trailingAnchor.constraint(equalTo: document.trailingAnchor),
        content.bottomAnchor.constraint(equalTo: document.bottomAnchor),
    ])
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true
    scroll.drawsBackground = false
    scroll.documentView = document
    document.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        document.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
        document.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
        document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
    ])
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.widthAnchor.constraint(equalToConstant: width).isActive = true
    scroll.heightAnchor.constraint(equalToConstant: height).isActive = true
    return scroll
}
