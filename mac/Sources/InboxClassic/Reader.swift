// The reading pane: the header of the message (From, Date, To, Cc, Subject) with the brand's logo at its left and the
// attachments and Unsubscribe at its right; under it the bar of a calendar invitation and the bar that offers the
// pictures from the internet; then the message itself. Every string shown is the core's, decoded and checked there.
import AppKit
import CInboxClassic

@MainActor
final class Reader: NSObject {
    let view = NSStackView()
    weak var mailbox: Mailbox?
    private let preview = Preview()
    private let header = NSTextField(wrappingLabelWithString: "")
    private let logo = NSImageView()
    private let attachments = NSPopUpButton(frame: .zero, pullsDown: true)
    private let unsubscribe = NSButton(title: Text.uiUnsubscribe.text, target: nil, action: nil)
    private let invitation = InfoBar(icon: "calendar_ltr", link: nil, button: Text.uiOpenInCalendar.text)
    private let pictures = InfoBar(icon: "image", link: nil)
    /// over a message that could not be downloaded: Try Again
    private let retry = InfoBar(icon: "arrow_sync", link: nil, button: Text.uiTryAgain.text)
    /// a moment after a message is asked for, the pane says it is being downloaded (one that is cached shows first)
    private var downloadingTimer: Timer?
    private(set) var picturesOffered = false
    /// over several messages: the numbers the core's page shows
    private var summary: PeSelectionSummary?
    /// the logo's side in pixels, for the core to draw it at
    var logoPixels: Int { Int(48 * (view.window?.backingScaleFactor ?? 2)) }

    override init() {
        super.init()
        header.isSelectable = true
        header.setAccessibilityIdentifier("reader.header")
        header.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        header.maximumNumberOfLines = 6
        logo.imageScaling = .scaleProportionallyUpOrDown
        logo.isHidden = true
        logo.widthAnchor.constraint(equalToConstant: 48).isActive = true
        logo.heightAnchor.constraint(equalToConstant: 48).isActive = true
        attachments.bezelStyle = .push
        attachments.isBordered = true
        attachments.setAccessibilityIdentifier("reader.attachments")
        attachments.isHidden = true
        attachments.menu?.delegate = self
        unsubscribe.isBordered = false
        unsubscribe.contentTintColor = .linkColor
        unsubscribe.attributedTitle = NSAttributedString(string: Text.uiUnsubscribe.text, attributes: [
            .foregroundColor: NSColor.linkColor, .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
        ])
        unsubscribe.target = self
        unsubscribe.action = #selector(unsubscribeClicked)
        unsubscribe.isHidden = true
        unsubscribe.setAccessibilityIdentifier("reader.unsubscribe")

        let right = NSStackView(views: [attachments, unsubscribe])
        right.orientation = .vertical
        right.alignment = .trailing
        let top = NSStackView(views: [logo, header, right])
        top.alignment = .top
        top.spacing = 10
        top.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        let headerBox = NSView()
        top.translatesAutoresizingMaskIntoConstraints = false
        headerBox.addSubview(top)
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: headerBox.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: headerBox.trailingAnchor),
            top.topAnchor.constraint(equalTo: headerBox.topAnchor),
            top.bottomAnchor.constraint(equalTo: headerBox.bottomAnchor),
        ])
        let line = NSBox()
        line.boxType = .separator

        pictures.text = Text.uiPicturesBlocked.text
        pictures.clicked = { [weak self] in self?.mailbox?.loadPictures() }
        pictures.setAccessibilityIdentifier("reader.pictures")
        invitation.clicked = { [weak self] in self?.mailbox?.openInCalendar() }
        retry.text = taken(pe_retry_note()) ?? ""
        retry.clicked = { [weak self] in self?.mailbox?.retryDownload() }
        retry.setAccessibilityIdentifier("reader.retry")
        retry.isHidden = true
        invitation.setAccessibilityIdentifier("reader.invitation")
        invitation.isHidden = true
        pictures.isHidden = true

        view.orientation = .vertical
        view.spacing = 0
        view.alignment = .leading
        for part in [headerBox, line, retry, invitation, pictures, preview.view] as [NSView] {
            view.addArrangedSubview(part)
            part.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        }
        view.setHuggingPriority(.defaultLow, for: .vertical)
        preview.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        invitation.heightAnchor.constraint(equalToConstant: 44).isActive = true
        pictures.heightAnchor.constraint(equalToConstant: 26).isActive = true
        retry.heightAnchor.constraint(equalToConstant: 34).isActive = true
        clear(loading: false)
    }

    /// several messages selected: none is shown, the core's page says how many and what they are (loaded again only
    /// when that changed)
    func showSummary(_ numbers: PeSelectionSummary) {
        if let summary, same(summary, numbers) { return }
        summary = numbers
        var numbers = numbers
        preview.show(taken(pe_selection_page(&numbers)) ?? "")
    }

    var showsSummary: Bool { summary != nil }

    private func same(_ a: PeSelectionSummary, _ b: PeSelectionSummary) -> Bool {
        a.count == b.count && a.unread == b.unread && a.flagged == b.flagged && a.in_junk == b.in_junk
            && a.accounts == b.accounts && a.folders == b.folders && a.for_good == b.for_good
    }

    // ---- what it shows ----

    func clear(loading: Bool) {
        summary = nil
        downloadingTimer?.invalidate()
        retry.isHidden = true
        header.stringValue = ""
        // the bars of the message before stay while the next one loads, and go when it is there without them
        if !loading {
            attachments.isHidden = true
            pictures.isHidden = true
            picturesOffered = false
        }
        unsubscribe.isHidden = true
        invitation.isHidden = true
        logo.isHidden = true
        logo.image = nil
        // says so rather than a blank pane, unless a message is about to be shown
        preview.clear(noMessage: !loading)
    }

    /// a message asked for: its header from the list at once, and after a moment, should it not be here yet, that it is
    /// being downloaded
    func showLoading(_ row: Message) {
        header.attributedStringValue = headerText(from: row.from, date: row.date, to: row.recipients, cc: "", subject: row.subject)
        retry.isHidden = true
        downloadingTimer?.invalidate()
        downloadingTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.showDownloading() }
        }
    }

    /// the message is here: being parsed now, not downloaded
    func arrived() {
        downloadingTimer?.invalidate()
        retry.isHidden = true
    }

    func showDownloading() {
        downloadingTimer?.invalidate()
        retry.isHidden = true
        preview.showState(PE_READER_STATE_DOWNLOADING)
    }

    /// the message could not be downloaded: why, in the pane, and Try Again over it
    func showFailed(kind: PeFailureKind, reason: String) {
        downloadingTimer?.invalidate()
        attachments.isHidden = true
        pictures.isHidden = true
        picturesOffered = false
        retry.isHidden = false
        preview.showState(PE_READER_STATE_FAILED, failure: kind, reason: reason)
    }

    var showsFailure: Bool { !retry.isHidden }

    func showProblem(_ problem: String) {
        downloadingTimer?.invalidate()
        header.stringValue = problem
        attachments.isHidden = true
        pictures.isHidden = true
        picturesOffered = false
    }

    func show(_ info: PeMessageInfo, view: MessageView, pictures allowed: Bool) {
        downloadingTimer?.invalidate()
        retry.isHidden = true
        header.attributedStringValue = headerText(info)
        let files = info.attachment_count
        attachments.isHidden = files == 0
        attachments.removeAllItems()
        // the title item of a pull-down button: the paper clip and how many files there are
        attachments.addItem(withTitle: Text.macFiles.text(["count": files]))
        attachments.item(at: 0)?.image = Icons.list("attach")
        // a mailing list that says how to leave it
        unsubscribe.isHidden = info.unsubscribe == PE_UNSUBSCRIBE_NONE
        showInvitation(info.invitation)
        preview.show(text(info.document), pictures: allowed)
        // offered only for a message with pictures on the internet, until they are shown
        picturesOffered = info.remote_images && !allowed
        pictures.isHidden = !picturesOffered
    }

    private func headerText(_ info: PeMessageInfo) -> NSAttributedString {
        headerText(from: text(info.from), date: info.has_date ? info.date : nil, to: text(info.to), cc: text(info.cc),
                   subject: text(info.subject))
    }

    /// From, Date, To (with Cc) and Subject, the names bold
    private func headerText(from: String, date: Int64?, to: String, cc: String, subject: String) -> NSAttributedString {
        let out = NSMutableAttributedString()
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let bold = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        func line(_ name: String, _ value: String, last: Bool = false) {
            out.append(NSAttributedString(string: name + ":  ", attributes: [.font: bold, .foregroundColor: NSColor.secondaryLabelColor]))
            out.append(NSAttributedString(string: value + (last ? "" : "\n"), attributes: [.font: font, .foregroundColor: NSColor.labelColor]))
        }
        line(Text.headerFrom.text, from)
        line(Text.headerDate.text, date.map(formatDate) ?? "")
        line(Text.headerTo.text, cc.isEmpty ? to : to + "    " + Text.headerCc.text + ":  " + cc)
        line(Text.headerSubject.text, subject, last: true)
        return out
    }

    func showLogo(_ pixels: Data?) {
        let side = logoPixels
        // the core's pixels: BGRA with the alpha multiplied in
        guard let pixels, pixels.count == side * side * 4, let provider = CGDataProvider(data: pixels as CFData),
              let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue
                                      | CGImageAlphaInfo.premultipliedFirst.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return }
        logo.image = NSImage(cgImage: image, size: NSSize(width: 48, height: 48))
        logo.isHidden = false
    }

    @objc private func unsubscribeClicked() {
        mailbox?.unsubscribe()
    }

    // ---- a calendar invitation ----

    private func showInvitation(_ event: UnsafePointer<PeInvitation>?) {
        guard let event = event?.pointee else {
            invitation.isHidden = true
            return
        }
        let kinds = [Text.uiInvitation, Text.uiInvitationUpdated, Text.uiInvitationCanceled, Text.uiInvitationAnswer]
        let summary = text(event.summary)
        let title = kinds[min(Int(event.kind.rawValue), 3)].text(["title": summary.isEmpty ? Text.uiNoTitle.text : summary])
        var parts = [when(event), text(event.location)]
        let organizer = text(event.organizer)
        if !organizer.isEmpty {
            parts.append(Text.uiOrganizer.text(["name": organizer]))
        }
        parts.append(text(event.repeats))
        if event.attendees > 0 {
            parts.append(Text.macAttendees.text(["count": event.attendees]))
        }
        invitation.title = title
        invitation.text = parts.filter { !$0.isEmpty }.joined(separator: "   \u{00B7}   ")
        invitation.isHidden = false
    }

    /// when an event is, in words: its day (or days) and times, as the reader's local time or as written (floating)
    private func when(_ event: PeInvitation) -> String {
        guard event.has_start else { return "" }
        let zone = event.floating ? TimeZone(secondsFromGMT: 0)! : TimeZone.current
        let day = DateFormatter()
        day.locale = Languages.locale
        day.dateStyle = .full
        day.timeStyle = .none
        day.timeZone = zone
        let time = DateFormatter()
        time.locale = Languages.locale
        time.dateStyle = .none
        time.timeStyle = .short
        time.timeZone = zone
        var calendar = Calendar.current
        calendar.timeZone = zone
        let start = Date(timeIntervalSince1970: TimeInterval(event.start))
        let end = event.has_end ? Date(timeIntervalSince1970: TimeInterval(event.end - (event.all_day ? 86400 : 0))) : nil
        if event.all_day {
            if let end, !calendar.isDate(start, inSameDayAs: end) {
                return Text.uiEventSpan.text(["start": day.string(from: start), "end": day.string(from: end)])
            }
            return day.string(from: start)
        }
        var said = day.string(from: start) + ", " + time.string(from: start)
        if let end {
            said = Text.uiEventSpan.text(["start": said, "end": calendar.isDate(start, inSameDayAs: end)
                ? time.string(from: end) : day.string(from: end) + ", " + time.string(from: end)])
        }
        return event.floating ? Text.uiEventFloating.text(["when": said]) : said
    }
}

// the attachment menu is made when it opens, from the message view
extension Reader: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let mailbox, menu === attachments.menu else { return }
        let title = menu.items.first?.copy() as? NSMenuItem
        menu.removeAllItems()
        if let title {
            menu.addItem(title)
        }
        for item in mailbox.attachmentMenu().items {
            item.menu?.removeItem(item)
            menu.addItem(item)
        }
    }
}

/// A bar in the colors of an information bar: an icon, a bold title and a line of text (or one line), clicked as a
/// whole or with a link or a button at its right
final class InfoBar: NSView {
    var clicked: () -> Void = {}
    var heightConstraint: NSLayoutConstraint?
    private let titleLabel = NSTextField(labelWithString: "")
    private let textLabel = NSTextField(labelWithString: "")
    private let action: NSButton?

    var title: String {
        get { titleLabel.stringValue }
        set {
            titleLabel.stringValue = newValue
            titleLabel.isHidden = newValue.isEmpty
        }
    }

    var text: String {
        get { textLabel.stringValue }
        set { textLabel.stringValue = newValue }
    }

    init(icon: String, link: String?, button: String? = nil) {
        if let button {
            action = NSButton(title: button, target: nil, action: nil)
            action?.bezelStyle = .push
        } else if let link {
            action = NSButton(title: link, target: nil, action: nil)
            action?.isBordered = false
            action?.attributedTitle = NSAttributedString(string: link, attributes: [
                .foregroundColor: NSColor.linkColor, .underlineStyle: NSUnderlineStyle.single.rawValue,
            ])
        } else {
            action = nil
        }
        super.init(frame: .zero)
        wantsLayer = true
        let image = NSImageView(image: Icons.list(icon) ?? NSImage())
        titleLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        titleLabel.isHidden = true
        titleLabel.lineBreakMode = .byTruncatingTail
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.textColor = .labelColor
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let words = NSStackView(views: [titleLabel, textLabel])
        words.orientation = .vertical
        words.alignment = .leading
        words.spacing = 1
        var views: [NSView] = [image, words]
        if let action {
            action.target = self
            action.action = #selector(fire)
            views.append(action)
            action.setContentHuggingPriority(.required, for: .horizontal)
        }
        let stack = NSStackView(views: views)
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            image.widthAnchor.constraint(equalToConstant: 16),
            image.heightAnchor.constraint(equalToConstant: 16),
        ])
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateLayer() {
        layer?.backgroundColor = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedRed: 0.32, green: 0.29, blue: 0.16, alpha: 1)
                : NSColor(calibratedRed: 1, green: 0.97, blue: 0.80, alpha: 1)
        }.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    // a bar without a link or button is clicked as a whole, like a link
    override func mouseDown(with event: NSEvent) {
        if action == nil {
            clicked()
        }
    }

    override func resetCursorRects() {
        if action == nil {
            addCursorRect(bounds, cursor: .pointingHand)
        }
    }

    @objc private func fire() {
        clicked()
    }

    override func accessibilityPerformPress() -> Bool {
        clicked()
        return true
    }
}
