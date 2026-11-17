// The security bar over a signed or encrypted message (under the header, above the pictures bar), in the colours of
// the page's part labels (pe-html's secure.rs), with pictures that carry its state without colour: the lock for an
// encrypted message, the shield with a check for a verified signature, the rosette for a good one, the warning sign
// for one that is not right, none for neutral. Its words are the core's; Details opens the Security Details window
// with the core's text of every part. A screen reader reads the bar first for the message.
import AppKit
import CInboxClassic

/// The colours of a tone: its border, its fill and its words, light and dark (secure.rs)
private struct ToneColors {
    let border: NSColor
    let fill: NSColor
    let words: NSColor

    init(_ light: (UInt32, UInt32, UInt32), _ dark: (UInt32, UInt32, UInt32)) {
        func pair(_ light: UInt32, _ dark: UInt32) -> NSColor {
            NSColor(name: nil) { appearance in
                rgb(appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light)
            }
        }
        border = pair(light.0, dark.0)
        fill = pair(light.1, dark.1)
        words = pair(light.2, dark.2)
    }

    static func of(_ tone: PeProtectionTone) -> ToneColors {
        switch tone {
        case PE_PROTECTION_TONE_VERIFIED: ToneColors((0x2e7d32, 0xe8f5e9, 0x1b5e20), (0x66bb6a, 0x1b3320, 0xa5d6a7))
        case PE_PROTECTION_TONE_GOOD: ToneColors((0x1f5fae, 0xe6eefa, 0x174a87), (0x7fb0f0, 0x1f2c40, 0xbcd6f7))
        case PE_PROTECTION_TONE_WARNING: ToneColors((0xb26a00, 0xfff4e0, 0x7a4800), (0xf0b45a, 0x3a2c14, 0xf6d29c))
        default: ToneColors((0x9e9e9e, 0xf2f2f2, 0x444444), (0x777777, 0x2a2a2a, 0xcccccc))
        }
    }
}

private func rgb(_ value: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((value >> 16) & 0xff) / 255, green: CGFloat((value >> 8) & 0xff) / 255,
            blue: CGFloat(value & 0xff) / 255, alpha: 1)
}

/// The bar: the pictures of its state, the core's words wrapped, Details at its end
@MainActor
final class SecurityBar: NSView {
    /// Details pressed
    var details: () -> Void = {}
    private(set) var tone = PE_PROTECTION_TONE_NONE
    private(set) var encrypted = false
    private let lock = NSImageView()
    private let mark = NSImageView()
    private let words = NSTextField(wrappingLabelWithString: "")
    let detailsButton = NSButton()
    private let line = NSView()
    private var colors = ToneColors.of(PE_PROTECTION_TONE_NEUTRAL)

    /// the SF Symbol of each tone; neutral has none
    static func symbol(_ tone: PeProtectionTone) -> String? {
        switch tone {
        case PE_PROTECTION_TONE_VERIFIED: "checkmark.shield.fill"
        case PE_PROTECTION_TONE_GOOD: "rosette"
        case PE_PROTECTION_TONE_WARNING: "exclamationmark.triangle.fill"
        default: nil
        }
    }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        isHidden = true
        setAccessibilityIdentifier("reader.security")
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        let symbols = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        for image in [lock, mark] {
            image.symbolConfiguration = symbols
            image.setContentHuggingPriority(.required, for: .horizontal)
            image.setContentCompressionResistancePriority(.required, for: .horizontal)
            image.widthAnchor.constraint(equalToConstant: 18).isActive = true
            // the words say it all: the pictures are not read out again
            image.setAccessibilityElement(false)
        }
        lock.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)
        lock.setAccessibilityIdentifier("reader.security.lock")
        mark.setAccessibilityIdentifier("reader.security.mark")
        words.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        words.isSelectable = false
        words.maximumNumberOfLines = 0
        words.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        words.setContentHuggingPriority(.init(1), for: .horizontal)
        words.setAccessibilityIdentifier("reader.security.words")
        detailsButton.title = Text.uiProtectionDetails.opens
        detailsButton.bezelStyle = .push
        detailsButton.controlSize = .small
        detailsButton.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
        detailsButton.target = self
        detailsButton.action = #selector(detailsClicked)
        detailsButton.setContentHuggingPriority(.required, for: .horizontal)
        detailsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailsButton.setAccessibilityIdentifier("reader.security.details")
        let row = NSStackView(views: [lock, mark, words, detailsButton])
        row.spacing = 6
        row.setCustomSpacing(10, after: words)
        row.alignment = .centerY
        row.detachesHiddenViews = true
        row.edgeInsets = NSEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        row.translatesAutoresizingMaskIntoConstraints = false
        line.wantsLayer = true
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        addSubview(line)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: line.topAnchor),
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1),
            // one line of words is as tall as the button with its margins, so the bar's height does not change
            // between messages
            heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// the words of the bar
    var said: String { words.stringValue }

    /// whether the lock, and which picture of the tone, are shown
    var pictures: (lock: Bool, mark: String?) {
        (!lock.isHidden, mark.isHidden ? nil : Self.symbol(tone))
    }

    /// the bar of a message: hidden for one without protection
    func show(_ info: PeMessageInfo) {
        tone = info.protection
        guard tone != PE_PROTECTION_TONE_NONE else {
            hide()
            return
        }
        encrypted = info.protection_encrypted
        colors = ToneColors.of(tone)
        let core = text(info.protection_text)
        words.stringValue = core
        words.textColor = colors.words
        lock.isHidden = !encrypted
        lock.contentTintColor = colors.words
        let symbol = Self.symbol(tone)
        mark.image = symbol.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: nil) }
        mark.isHidden = symbol == nil
        mark.contentTintColor = colors.border
        setAccessibilityLabel(core)
        needsDisplay = true
        isHidden = false
    }

    func hide() {
        tone = PE_PROTECTION_TONE_NONE
        encrypted = false
        isHidden = true
    }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = colors.fill.cgColor
            line.layer?.backgroundColor = colors.border.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    @objc private func detailsClicked() {
        details()
    }
}

// ---- Security Details ----

/// The window of Details: the core's text of every part (its label, the key that signed it and when, the key that
/// opened it), read only and selectable, Close; the help opens the topic of signed and encrypted mail
@MainActor
enum SecurityDetails {
    static func run(_ details: String, owner: NSWindow?) {
        let window = TextDialogWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 300),
                                      styleMask: [.titled, .resizable], backing: .buffered, defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiProtectionDetailsTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("protection.details")
        let scroll = NSTextView.scrollableTextView()
        scroll.borderType = .bezelBorder
        let view = scroll.documentView as! NSTextView
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = true
        view.textContainerInset = NSSize(width: 6, height: 8)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        style.paragraphSpacing = 4
        view.textStorage?.setAttributedString(NSAttributedString(string: details, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize), .foregroundColor: NSColor.labelColor,
            .paragraphStyle: style,
        ]))
        view.setAccessibilityIdentifier("protection.details.text")
        view.setAccessibilityLabel(window.title)
        let close = NSButton(title: Text.uiClose.text, target: NSApp,
                             action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
        close.keyEquivalent = "\r"
        close.setAccessibilityIdentifier("protection.details.close")
        let buttons = buttonRow([close], help: "protection-details")
        let stack = NSStackView(views: [scroll, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        scroll.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        scroll.widthAnchor.constraint(greaterThanOrEqualToConstant: 520).isActive = true
        buttons.widthAnchor.constraint(equalTo: scroll.widthAnchor).isActive = true
        // as tall as the text, up to a screenful's share; longer scrolls
        let height = textHeight(view.attributedString(), width: 520 - 12 - 10)
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: min(max(height + 20, 120), 420)).isActive = true
        window.contentView = stack
        window.setContentSize(stack.fittingSize)
        window.contentMinSize = NSSize(width: 400, height: 200)
        window.initialFirstResponder = close
        if let owner {
            let frame = owner.frame
            window.setFrameOrigin(NSPoint(x: frame.midX - window.frame.width / 2, y: frame.midY - window.frame.height / 2))
        } else {
            window.center()
        }
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
    }

    /// the height of `text` laid out `width` wide
    private static func textHeight(_ text: NSAttributedString, width: CGFloat) -> CGFloat {
        ceil(text.boundingRect(with: NSSize(width: width, height: .greatestFiniteMagnitude),
                               options: [.usesLineFragmentOrigin, .usesFontLeading]).height)
    }
}
