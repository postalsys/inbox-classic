// The reading pane's message, or its whole conversation, as a native stack (docs/conversation-view-plan.md): the
// conversation's subject and who is in it, then a row for each folded message and a frame for each open one, its body
// a web view of the message's own document as tall as the document, the stack scrolling as one. The words and the
// choices are the core's (pe_conversation_entry); a click is handed to the core (pe_conversation_click) and the view
// is built again, the frames of the same messages kept with their web views.
import AppKit
import CInboxClassic

/// One message of a conversation's stack, copied out of the core's view
struct ConversationEntry {
    let folder: Int64
    let uid: UInt64
    let index: Int
    let from: String
    let address: String
    let own: Bool
    let date: Int64
    let when: String
    let words: String
    let to: String
    let inFolder: String
    let foundIn: String
    let note: String
    let draft: Bool
    let unread: Bool
    let open: Bool
    let selected: Bool
    let attachments: Bool
    let reactions: String
    let picture: UInt64
    let logo: Bool
    let initials: String
    let hiddenBefore: Int
    let hiddenText: String

    init(_ entry: PeConversationEntry) {
        folder = entry.folder
        uid = entry.uid
        index = entry.index
        from = text(entry.from)
        address = text(entry.address)
        own = entry.own
        date = entry.date
        when = text(entry.when)
        words = text(entry.words)
        to = text(entry.to)
        inFolder = text(entry.in_folder)
        foundIn = text(entry.found_in)
        note = text(entry.note)
        draft = entry.draft
        unread = entry.unread
        open = entry.open
        selected = entry.selected
        attachments = entry.attachments
        reactions = text(entry.reactions)
        picture = entry.picture
        logo = entry.logo
        initials = text(entry.initials)
        hiddenBefore = entry.hidden_before
        hiddenText = text(entry.hidden_text)
    }

    /// the frame it is shown in: a message of a conversation by its own key; a message alone the core's 0, 0, always
    /// the same frame, so showing the next message loads it into the web view there
    var key: ConversationStack.Key { .init(folder: folder, uid: uid) }
}

/// What a frame's buttons and menus ask of the reader: each on the frame's message (`entry`)
@MainActor
struct StackActions {
    var click: (PeConversationClick, ConversationEntry) -> Void = { _, _ in }
    var command: (Command, ConversationEntry) -> Void = { _, _ in }
    var more: (ConversationEntry, NSView) -> Void = { _, _ in }
    var edit: (ConversationEntry) -> Void = { _ in }
    var openWindow: (ConversationEntry) -> Void = { _ in }
    var link: (String) -> Bool = { _ in false }
}

/// The stack: a scroll view of the conversation's title, its rows and frames
@MainActor
final class ConversationStack: NSScrollView {
    struct Key: Hashable {
        let folder: Int64
        let uid: UInt64
    }

    var core: Core?
    var actions = StackActions()
    /// the reader's own views put into the selected frame: the reactions under its header, the files under its body
    var selectedExtras: (reactions: NSView, files: NSView, filesMenu: NSView)?
    /// the pictures of the senders, kept for the run
    var pictures: ListPictures? {
        didSet { pictures?.arrived = { [weak self] _ in self?.picturesArrived() } }
    }

    private let column = FlippedView()
    private let items = NSStackView()
    private let subject = NSTextField(wrappingLabelWithString: "")
    private let summary = NSTextField(labelWithString: "")
    private var frames: [Key: StackFrame] = [:]
    private var rows: [FoldedRow] = []

    /// the selected frame's body: Find, the UI test and Print act on it
    var selectedBody: Preview? { frames.values.first { $0.selected }?.body }

    override init(frame: NSRect) {
        super.init(frame: frame)
        hasVerticalScroller = true
        hasHorizontalScroller = false
        autohidesScrollers = true
        drawsBackground = true
        borderType = .noBorder
        // the web views of the bodies drawn only inside the pane, never over the status bar under it
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = true
        paintBackground()
        setAccessibilityIdentifier("reader.stack")
        column.translatesAutoresizingMaskIntoConstraints = false
        documentView = column
        subject.font = .systemFont(ofSize: 15, weight: .semibold)
        subject.setAccessibilityIdentifier("stack.subject")
        subject.isSelectable = true
        summary.font = .systemFont(ofSize: 12)
        summary.textColor = .secondaryLabelColor
        summary.lineBreakMode = .byTruncatingTail
        summary.setAccessibilityIdentifier("stack.summary")
        let title = NSStackView(views: [subject, summary])
        title.orientation = .vertical
        title.alignment = .leading
        title.spacing = 2
        items.orientation = .vertical
        items.alignment = .leading
        items.spacing = 8
        let all = NSStackView(views: [title, items])
        all.orientation = .vertical
        all.alignment = .leading
        all.spacing = 10
        all.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 16, right: 12)
        all.translatesAutoresizingMaskIntoConstraints = false
        column.addSubview(all)
        NSLayoutConstraint.activate([
            column.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            all.leadingAnchor.constraint(equalTo: column.leadingAnchor),
            all.trailingAnchor.constraint(equalTo: column.trailingAnchor),
            all.topAnchor.constraint(equalTo: column.topAnchor),
            all.bottomAnchor.constraint(equalTo: column.bottomAnchor),
            title.widthAnchor.constraint(equalTo: all.widthAnchor, constant: -24),
            items.widthAnchor.constraint(equalTo: all.widthAnchor, constant: -24),
            subject.widthAnchor.constraint(equalTo: title.widthAnchor),
            summary.widthAnchor.constraint(lessThanOrEqualTo: title.widthAnchor),
        ])
        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(scrolled), name: NSView.boundsDidChangeNotification,
                                               object: contentView)
        // and laid out again (frames added, bodies measured): a frame given its place only now is made when near
        column.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(scrolled), name: NSView.frameDidChangeNotification,
                                               object: column)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// a conversation's messages are cards on a soft gray, as Mail has them (the window's own background is white
    /// since macOS 26, so the gray is the stack's own, a shade under the cards in either appearance); a message alone
    /// is on the page itself
    private static let cardsBackground = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(white: 0.09, alpha: 1) : NSColor(white: 0.955, alpha: 1)
    }
    private var fill: NSColor = cardsBackground

    /// the fill on the clip view's own layer too: a layer-backed clip view does not draw the scroll view's background
    private func paintBackground() {
        backgroundColor = fill
        effectiveAppearance.performAsCurrentDrawingAppearance {
            contentView.layer?.backgroundColor = fill.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        paintBackground()
    }

    /// Left and Right with the stack in front: every message folded but the selected one, or every one open, as
    /// Left and Right close and open a conversation's row in the list
    var keys: (PeConversationClick) -> Void = { _ in }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: keys(PE_CONVERSATION_CLICK_FOLD_ALL)
        case 124: keys(PE_CONVERSATION_CLICK_OPEN_ALL)
        default: super.keyDown(with: event)
        }
    }

    /// the view `view` (`info` its selected message's): its title and its entries, the frames of messages already shown
    /// kept; `start` scrolls to the selected message (a conversation shown anew), else the stack stays where it was
    func show(_ view: MessageView, info: PeMessageInfo, entries: [ConversationEntry], pictures allowed: Bool, start: Bool) {
        let conversation = info.conversation_count > 0
        fill = conversation ? Self.cardsBackground : .textBackgroundColor
        paintBackground()
        subject.stringValue = conversation ? text(info.conversation_subject) : text(info.subject)
        summary.stringValue = text(info.conversation_line)
        summary.isHidden = summary.stringValue.isEmpty
        for row in rows {
            row.removeFromSuperview()
        }
        rows.removeAll()
        for item in items.arrangedSubviews {
            items.removeArrangedSubview(item)
            item.removeFromSuperview()
        }
        let open = Set(entries.filter(\.open).map(\.key))
        for (key, frame) in frames where !open.contains(key) {
            frame.release()
            frames[key] = nil
        }
        var group: RowGroup?
        for (place, entry) in entries.enumerated() {
            if entry.hiddenBefore > 0 {
                group = nil
                add(gapButton(entry))
            }
            if entry.open {
                group = nil
                let frame = frames[entry.key] ?? StackFrame(core: core, actions: actions)
                frames[entry.key] = frame
                let own = conversation ? view.entryView(place) : view
                frame.show(entry, view: own, conversation: conversation, pictures: allowed && entry.selected,
                           picture: picture(of: entry))
                if entry.selected, let extras = selectedExtras {
                    frame.take(extras)
                }
                add(frame)
            } else {
                if group == nil {
                    let made = RowGroup()
                    group = made
                    add(made)
                }
                let row = FoldedRow(entry: entry, picture: picture(of: entry), actions: actions)
                rows.append(row)
                group?.add(row)
            }
        }
        column.layoutSubtreeIfNeeded()
        if start, let selected = frames.values.first(where: { $0.selected }) {
            scrollTo(selected)
        }
        scrolled()
    }

    /// the folded middle of a long conversation before `entry`: "14 more messages", a click lists them
    private func gapButton(_ entry: ConversationEntry) -> NSButton {
        let gap = ClosureButton { [weak self] _ in self?.actions.click(PE_CONVERSATION_CLICK_SHOW_MIDDLE, entry) }
        gap.title = entry.hiddenText
        gap.isBordered = false
        gap.contentTintColor = .controlAccentColor
        gap.font = .systemFont(ofSize: 12)
        gap.alignment = .center
        gap.setAccessibilityIdentifier("stack.middle")
        gap.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return gap
    }

    private func add(_ item: NSView) {
        items.addArrangedSubview(item)
        item.widthAnchor.constraint(equalTo: items.widthAnchor).isActive = true
    }

    /// nothing shown: the frames and their web views let go
    func clear() {
        for frame in frames.values {
            frame.release()
        }
        frames.removeAll()
        rows.removeAll()
        for item in items.arrangedSubviews {
            items.removeArrangedSubview(item)
            item.removeFromSuperview()
        }
    }

    /// the frame scrolled to its top; the title kept in view when the frame starts on the first screen
    private func scrollTo(_ frame: NSView) {
        let place = frame.convert(frame.bounds, to: column).minY
        let top = place < contentView.bounds.height ? 0 : place - 8
        let room = max(0, column.bounds.height - contentView.bounds.height)
        contentView.scroll(to: NSPoint(x: 0, y: min(top, room)))
        reflectScrolledClipView(contentView)
    }

    /// the stack scrolled or laid out: the bodies near what is seen made, those far from it let go (their heights
    /// kept), so a long conversation with many open messages holds only a few web views
    @objc private func scrolled() {
        let seen = contentView.documentVisibleRect.insetBy(dx: 0, dy: -2 * max(contentView.bounds.height, 400))
        for frame in frames.values {
            let place = frame.convert(frame.bounds, to: column)
            frame.live(frame.selected || place.intersects(seen))
        }
    }

    /// the selected message's own picture, drawn for it (a message alone: its brand's logo)
    func selectedPicture(_ image: NSImage) {
        frames.values.first { $0.selected }?.setPicture(image)
    }

    private func picture(of entry: ConversationEntry) -> (image: NSImage?, initials: String) {
        let scale = window?.backingScaleFactor ?? 2
        return (pictures?.image(entry.picture, points: SenderPicture.size, scale: scale), entry.initials)
    }

    private func picturesArrived() {
        for frame in frames.values {
            frame.picture(pictures, scale: window?.backingScaleFactor ?? 2)
        }
        for row in rows {
            row.picture(pictures, scale: window?.backingScaleFactor ?? 2)
        }
    }

    // ---- for the UI test ----

    /// the frames and rows in the stack's order: the message's sender, open, selected
    var shown: [(from: String, open: Bool, selected: Bool)] {
        items.arrangedSubviews.flatMap { item -> [(String, Bool, Bool)] in
            if let frame = item as? StackFrame, let entry = frame.entry { return [(entry.from, true, entry.selected)] }
            if let group = item as? RowGroup { return group.rows.map { ($0.entry.from, false, false) } }
            return []
        }
    }

    var frameViews: [StackFrame] { items.arrangedSubviews.compactMap { $0 as? StackFrame } }

    /// where `frame` is in the column and what the stack counts as near what is seen, for a failed check
    func placeForTest(_ frame: StackFrame) -> String {
        let place = frame.convert(frame.bounds, to: column)
        let seen = contentView.documentVisibleRect
        return "at \(Int(place.minY)) to \(Int(place.maxY)), seen \(Int(seen.minY)) to \(Int(seen.maxY))"
    }
    var rowViews: [FoldedRow] { rows }
    var gapViews: [NSButton] {
        items.arrangedSubviews.compactMap { $0 as? NSButton }.filter { $0.accessibilityIdentifier() == "stack.middle" }
    }
}

// ---- an open message ----

/// An open message: a strip saying where it is filed (when not here), its header (the arrow, the sender's picture and
/// name, to whom and when, its buttons), its body as tall as its document, its files
@MainActor
final class StackFrame: NSView {
    private(set) var entry: ConversationEntry?
    private(set) var body: Preview?
    var selected: Bool { entry?.selected == true }
    private let core: Core?
    private let actions: StackActions
    private let foundIn = NSTextField(labelWithString: "")
    private let arrow = NSButton()
    private let face = SenderPicture()
    private let name = NSTextField(labelWithString: "")
    private let detail = NSTextField(labelWithString: "")
    private let buttons = NSStackView()
    private let headerBox = NSView()
    private let content = NSStackView()
    private let bodyBox = NSView()
    private var bodyHeight: NSLayoutConstraint!
    private let files = NSButton()
    /// the view whose document the body shows, and whether its pictures are let through: kept to make the body again
    private var view: MessageView?
    private var pictures = false
    /// the document's height last measured, in points: the frame keeps it while its body is let go
    private var height: CGFloat = 120
    private var fitted = false
    private var extras: (reactions: NSView, files: NSView, filesMenu: NSView)?
    /// a card with an outline (a message of a conversation), or on the page itself (a message alone)
    private var framed = true
    /// the hairline between the header and what the message holds
    private let rule = NSBox()

    init(core: Core?, actions: StackActions) {
        self.core = core
        self.actions = actions
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityIdentifier("stack.frame")

        foundIn.font = .systemFont(ofSize: 11)
        foundIn.textColor = .secondaryLabelColor
        foundIn.setAccessibilityIdentifier("frame.foundIn")
        arrow.isBordered = false
        arrow.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: Text.uiConversationFoldMessage.text)
        arrow.imageScaling = .scaleProportionallyDown
        arrow.contentTintColor = .secondaryLabelColor
        arrow.target = self
        arrow.action = #selector(arrowClicked)
        arrow.setAccessibilityIdentifier("frame.arrow")
        arrow.widthAnchor.constraint(equalToConstant: 22).isActive = true
        arrow.heightAnchor.constraint(equalToConstant: 28).isActive = true
        face.widthAnchor.constraint(equalToConstant: SenderPicture.size).isActive = true
        face.heightAnchor.constraint(equalToConstant: SenderPicture.size).isActive = true
        name.font = .systemFont(ofSize: 13, weight: .semibold)
        name.textColor = .labelColor
        name.lineBreakMode = .byTruncatingTail
        name.setAccessibilityIdentifier("frame.name")
        detail.font = .systemFont(ofSize: 12)
        detail.textColor = .secondaryLabelColor
        detail.lineBreakMode = .byTruncatingTail
        detail.setAccessibilityIdentifier("frame.detail")
        for label in [name, detail] {
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        let who = NSStackView(views: [name, detail])
        who.orientation = .vertical
        who.alignment = .leading
        who.spacing = 1
        who.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        buttons.spacing = 2
        buttons.setContentHuggingPriority(.required, for: .horizontal)
        // the buttons in the trailing gravity, at the header's trailing edge as Mail's
        let header = NSStackView()
        header.setViews([arrow, face, who], in: .leading)
        header.setViews([buttons], in: .trailing)
        header.alignment = .centerY
        header.spacing = 8
        header.edgeInsets = NSEdgeInsets(top: 8, left: 6, bottom: 8, right: 8)
        header.translatesAutoresizingMaskIntoConstraints = false
        headerBox.addSubview(header)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: headerBox.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: headerBox.trailingAnchor),
            header.topAnchor.constraint(equalTo: headerBox.topAnchor),
            header.bottomAnchor.constraint(equalTo: headerBox.bottomAnchor),
        ])
        bodyHeight = bodyBox.heightAnchor.constraint(equalToConstant: height)
        bodyHeight.isActive = true
        files.isBordered = false
        files.alignment = .left
        files.contentTintColor = .secondaryLabelColor
        files.target = self
        files.action = #selector(filesClicked)
        files.setAccessibilityIdentifier("frame.files")
        rule.boxType = .separator

        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 0
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
        ])
        let click = NSClickGestureRecognizer(target: self, action: #selector(clicked))
        click.delaysPrimaryMouseButtonEvents = false
        headerBox.addGestureRecognizer(click)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// shows `entry`, its body `view`'s document (made now when the frame is near what is seen)
    func show(_ entry: ConversationEntry, view: MessageView?, conversation: Bool, pictures: Bool,
              picture: (image: NSImage?, initials: String)) {
        // another document, or the same built again: its previews under the new view's token
        let documentChanged = !Self.sameDocument(self.view, view) || self.pictures != pictures
        self.entry = entry
        self.view = view
        self.pictures = pictures
        foundIn.stringValue = entry.foundIn
        name.stringValue = entry.from
        name.toolTip = entry.address.isEmpty ? nil : entry.address
        let when = entry.when
        detail.stringValue = [entry.to, when].filter { !$0.isEmpty }.joined(separator: " · ")
        face.image = picture.image
        face.initials = picture.initials
        arrow.isHidden = !conversation
        framed = conversation
        setAccessibilityLabel([entry.from, when].joined(separator: ", "))
        buttons.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if entry.draft {
            buttons.addArrangedSubview(button(Text.uiConversationEdit.text, symbol: "square.and.pencil", id: "frame.edit") { [weak self] _ in
                guard let self, let entry = self.entry else { return }
                actions.edit(entry)
            })
        } else {
            for (command, symbol) in [(Command.reply, "arrowshape.turn.up.left"), (.replyAll, "arrowshape.turn.up.left.2"),
                                      (.forward, "arrowshape.turn.up.right")] {
                buttons.addArrangedSubview(button(command.label, symbol: symbol, id: "frame.\(command)") { [weak self] _ in
                    guard let self, let entry = self.entry else { return }
                    actions.command(command, entry)
                })
            }
        }
        buttons.addArrangedSubview(button(Text.uiConversationMore.text, symbol: "ellipsis.circle", id: "frame.more") { [weak self] more in
            guard let self, let entry = self.entry else { return }
            actions.more(entry, more)
        })
        // what goes in it: where it is filed, its header, its reactions and files when selected, its body
        content.arrangedSubviews.forEach { content.removeArrangedSubview($0); $0.removeFromSuperview() }
        if !entry.foundIn.isEmpty {
            let strip = NSStackView(views: [NSImageView(image: NSImage(systemSymbolName: "folder", accessibilityDescription: nil)!),
                                            foundIn])
            strip.spacing = 4
            strip.edgeInsets = NSEdgeInsets(top: 5, left: 12, bottom: 0, right: 12)
            (strip.arrangedSubviews[0] as? NSImageView)?.contentTintColor = .tertiaryLabelColor
            put(strip)
        }
        put(headerBox)
        put(rule, inset: 12)
        content.setCustomSpacing(8, after: rule)
        extras = nil
        if !entry.selected {
            let count = view?.info?.pointee.attachment_count ?? 0
            files.isHidden = count == 0
            if count > 0, let view {
                let names = view.attachments.map(\.name).joined(separator: ", ")
                files.title = "📎 " + Text.macFiles.text(["count": count]) + ": " + names
            }
        }
        put(bodyBox)
        if !entry.selected && !files.isHidden {
            put(files, inset: 12)
        }
        restyle()
        // another document (the next message alone, its pictures now, built again): loaded into the web view there
        if documentChanged, let body {
            load(body)
        }
    }

    /// whether `a` and `b` show the same document under the same preview token, compared where the core keeps them
    private static func sameDocument(_ a: MessageView?, _ b: MessageView?) -> Bool {
        func same(_ x: UnsafePointer<CChar>?, _ y: UnsafePointer<CChar>?) -> Bool {
            guard let x, let y else { return x == nil && y == nil }
            return x == y || strcmp(x, y) == 0
        }
        if a === b { return true }
        let a = a?.info?.pointee, b = b?.info?.pointee
        guard let a, let b else { return a == nil && b == nil }
        return same(a.preview_token, b.preview_token) && same(a.document, b.document)
    }

    /// the body shows the view's document: its parts, its previews, its pictures from the internet when let through
    private func load(_ body: Preview) {
        guard let view, let info = view.info?.pointee else { return }
        let parts = info.part_count > 0 ? { [view] (index: Int) in view.part(index) } : nil
        body.show(text(info.document), pictures: pictures || info.pictures_loaded, parts: parts,
                  previews: text(info.preview_token))
    }

    /// the selected frame takes the reader's reactions row and files strip (under its header, before its body)
    func take(_ extras: (reactions: NSView, files: NSView, filesMenu: NSView)) {
        self.extras = extras
        extras.filesMenu.removeFromSuperview()
        buttons.insertArrangedSubview(extras.filesMenu, at: 0)
        let headerAt = content.arrangedSubviews.firstIndex(of: headerBox) ?? 0
        extras.reactions.removeFromSuperview()
        content.insertArrangedSubview(extras.reactions, at: headerAt + 1)
        extras.reactions.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -56).isActive = true
        let reactionsPad = NSLayoutConstraint(item: extras.reactions, attribute: .leading, relatedBy: .equal, toItem: content,
                                              attribute: .leading, multiplier: 1, constant: 50)
        reactionsPad.isActive = true
        // its files under its header, before its body, as Tab reaches them
        extras.files.removeFromSuperview()
        let bodyAt = content.arrangedSubviews.firstIndex(of: bodyBox) ?? content.arrangedSubviews.count
        content.insertArrangedSubview(extras.files, at: bodyAt)
        extras.files.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        // room between the files and the text (the rule above them has its own)
        content.setCustomSpacing(6, after: extras.files)
    }

    private func put(_ part: NSView, inset: CGFloat = 0) {
        content.addArrangedSubview(part)
        part.widthAnchor.constraint(equalTo: content.widthAnchor, constant: -2 * inset).isActive = true
    }

    private func button(_ title: String, symbol: String, id: String, _ run: @escaping (NSButton) -> Void) -> NSButton {
        let label = title.replacingOccurrences(of: "&", with: "").replacingOccurrences(of: "...", with: "")
        let made = ClosureButton(run: run)
        // a picture only: its words are its accessibility label and tooltip
        made.title = ""
        made.imagePosition = .imageOnly
        made.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        made.isBordered = false
        made.bezelStyle = .accessoryBarAction
        made.toolTip = label
        made.setAccessibilityLabel(label)
        made.setAccessibilityIdentifier(id)
        made.contentTintColor = .secondaryLabelColor
        made.widthAnchor.constraint(equalToConstant: 26).isActive = true
        made.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return made
    }

    /// a light card as Mail's: a hairline around every frame, the selected one's faintly in the accent color
    func restyle() {
        let selected = self.selected
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.borderColor = (selected ? NSColor.controlAccentColor.withAlphaComponent(0.45) : NSColor.separatorColor).cgColor
            layer?.borderWidth = framed ? 1 : 0
            layer?.cornerRadius = framed ? 10 : 0
            layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        }
        setAccessibilitySelected(selected)
        body?.view.setAccessibilityIdentifier(selected ? "preview" : "frame.body")
        needsDisplay = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        restyle()
    }

    /// the body made (near what is seen, or selected) or let go (far from it), its height kept
    func live(_ near: Bool) {
        if near, body == nil, view?.info != nil {
            let made = Preview()
            made.core = core
            made.links = { [weak self] link in
                guard let self else { return false }
                return actions.link(link)
            }
            made.fitted = { [weak self] points in self?.fit(points) }
            made.view.setAccessibilityIdentifier(selected ? "preview" : "frame.body")
            (made.view as? ReadingView)?.clicked = { [weak self] in self?.clicked() }
            made.view.translatesAutoresizingMaskIntoConstraints = false
            bodyBox.addSubview(made.view)
            NSLayoutConstraint.activate([
                made.view.leadingAnchor.constraint(equalTo: bodyBox.leadingAnchor, constant: 4),
                made.view.trailingAnchor.constraint(equalTo: bodyBox.trailingAnchor, constant: -2),
                made.view.topAnchor.constraint(equalTo: bodyBox.topAnchor),
                made.view.bottomAnchor.constraint(equalTo: bodyBox.bottomAnchor),
            ])
            load(made)
            body = made
        } else if !near, body != nil, !selected {
            body?.view.removeFromSuperview()
            body = nil
        }
    }

    /// the frame no longer shown: its body let go
    func release() {
        body?.view.removeFromSuperview()
        body = nil
        view = nil
    }

    private func fit(_ points: CGFloat) {
        fitted = true
        let points = max(48, ceil(points))
        guard abs(points - height) >= 1 else { return }
        height = points
        bodyHeight.constant = points
    }

    func picture(_ pictures: ListPictures?, scale: CGFloat) {
        guard let entry, entry.picture != 0, face.image == nil else { return }
        face.image = pictures?.image(entry.picture, points: SenderPicture.size, scale: scale)
    }

    func setPicture(_ image: NSImage) {
        face.image = image
    }

    // ---- for the UI test ----

    /// a click on the frame, as the user's selects its message
    func selectForTest() {
        clicked()
    }

    var arrowForTest: NSButton { arrow }

    /// whether its body was measured once (it keeps its height when let go)
    var fittedForTest: Bool { fitted }

    /// its body's height in points, and whether its document is taller than a body is made, so it scrolls by itself
    var tallForTest: (height: CGFloat, scrollsItself: Bool) {
        (height, fitted && (body?.view as? ReadingView)?.fitsContent == false)
    }

    /// what its body is, for a failed check: made or not, measured or not, its height
    var bodyForTest: String {
        let shown = view == nil ? "no view" : view?.info == nil ? "no info" : "a view"
        return "\(body == nil ? "none" : "made"), \(fitted ? "measured" : "not measured"), \(Int(height)), \(shown)"
    }

    /// the sender's picture drawn in its header (a brand's logo, a contact's picture); nil for the initials
    var pictureForTest: NSImage? { face.image }

    /// the frame's own button with the identifier `id` ("frame.reply", "frame.more", "frame.edit")
    func buttonForTest(_ id: String) -> NSButton? {
        buttons.arrangedSubviews.compactMap { $0 as? NSButton }.first { $0.accessibilityIdentifier() == id }
    }

    @objc private func clicked() {
        guard let entry, !entry.selected else { return }
        actions.click(PE_CONVERSATION_CLICK_SELECT, entry)
    }

    @objc private func arrowClicked() {
        guard let entry else { return }
        actions.click(PE_CONVERSATION_CLICK_TOGGLE, entry)
    }

    @objc private func filesClicked() {
        clicked()
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2, let entry {
            actions.openWindow(entry)
            return
        }
        clicked()
    }
}

/// A button that runs a closure, handed the button (a frame's buttons, the folded middle of a long conversation)
final class ClosureButton: NSButton {
    private let run: (NSButton) -> Void

    init(run: @escaping (NSButton) -> Void) {
        self.run = run
        super.init(frame: .zero)
        target = self
        action = #selector(pressed)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func pressed() { run(self) }
}

// ---- folded messages ----

/// Folded messages next to each other: one box, a hairline between its rows
@MainActor
final class RowGroup: NSView {
    private let stack = NSStackView()
    private(set) var rows: [FoldedRow] = []

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.list)
        restyle()
    }

    required init?(coder: NSCoder) { fatalError() }

    func add(_ row: FoldedRow) {
        if !rows.isEmpty {
            let line = NSBox()
            line.boxType = .separator
            stack.addArrangedSubview(line)
            line.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        rows.append(row)
        stack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    private func restyle() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        restyle()
    }
}

/// A folded message: the arrow, the sender's picture and name, where it is filed, its first words, a paperclip, its
/// reactions and its date; a click opens it, a double-click opens it in a window of its own
@MainActor
final class FoldedRow: NSView {
    let entry: ConversationEntry
    private let actions: StackActions
    private let face = SenderPicture()
    private var hovered = false { didSet { needsDisplay = true } }

    init(entry: ConversationEntry, picture: (image: NSImage?, initials: String), actions: StackActions) {
        self.entry = entry
        self.actions = actions
        super.init(frame: .zero)
        heightAnchor.constraint(equalToConstant: 36).isActive = true
        let arrow = NSButton()
        arrow.isBordered = false
        arrow.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: Text.uiConversationOpenMessage.text)
        arrow.imageScaling = .scaleProportionallyDown
        arrow.contentTintColor = .secondaryLabelColor
        arrow.target = self
        arrow.action = #selector(arrowClicked)
        arrow.setAccessibilityIdentifier("row.arrow")
        arrow.widthAnchor.constraint(equalToConstant: 22).isActive = true
        arrow.heightAnchor.constraint(equalToConstant: 28).isActive = true
        face.image = picture.image
        face.initials = picture.initials
        face.widthAnchor.constraint(equalToConstant: 22).isActive = true
        face.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let name = NSTextField(labelWithString: entry.from)
        name.font = .systemFont(ofSize: 13, weight: entry.unread ? .bold : .medium)
        name.lineBreakMode = .byTruncatingTail
        name.setContentCompressionResistancePriority(.init(740), for: .horizontal)
        name.setContentHuggingPriority(.required, for: .horizontal)
        name.setAccessibilityIdentifier("row.name")
        var parts: [NSView] = [arrow, face, name]
        for chip in [entry.inFolder, entry.note] where !chip.isEmpty {
            let label = NSTextField(labelWithString: chip)
            label.font = .systemFont(ofSize: 10.5)
            label.textColor = .secondaryLabelColor
            label.wantsLayer = true
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.init(730), for: .horizontal)
            label.setAccessibilityIdentifier("row.chip")
            parts.append(label)
        }
        let words = NSTextField(labelWithString: entry.words)
        words.font = .systemFont(ofSize: 12.5)
        words.textColor = .secondaryLabelColor
        words.lineBreakMode = .byTruncatingTail
        words.setContentCompressionResistancePriority(.init(100), for: .horizontal)
        words.setContentHuggingPriority(.init(100), for: .horizontal)
        words.setAccessibilityIdentifier("row.words")
        parts.append(words)
        if entry.attachments {
            let clip = NSImageView(image: NSImage(systemSymbolName: "paperclip", accessibilityDescription: nil)!)
            clip.contentTintColor = .secondaryLabelColor
            parts.append(clip)
        }
        if !entry.reactions.isEmpty {
            let reactions = NSTextField(labelWithString: entry.reactions)
            reactions.font = .systemFont(ofSize: 12)
            reactions.setContentHuggingPriority(.required, for: .horizontal)
            reactions.setAccessibilityIdentifier("row.reactions")
            parts.append(reactions)
        }
        let date = NSTextField(labelWithString: entry.date > 0 ? shortDate(entry.date, at: DateClock()) : "")
        date.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        date.textColor = .secondaryLabelColor
        date.setContentHuggingPriority(.required, for: .horizontal)
        date.setContentCompressionResistancePriority(.required, for: .horizontal)
        date.setAccessibilityIdentifier("row.date")
        parts.append(date)
        let line = NSStackView(views: parts)
        line.alignment = .centerY
        line.spacing = 8
        line.edgeInsets = NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 10)
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.topAnchor.constraint(equalTo: topAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        toolTip = entry.when
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel([entry.from, entry.inFolder, entry.note, entry.words, entry.when].filter { !$0.isEmpty }
            .joined(separator: ", "))
        setAccessibilityIdentifier("stack.row")
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    required init?(coder: NSCoder) { fatalError() }

    override func accessibilityPerformPress() -> Bool {
        actions.click(PE_CONVERSATION_CLICK_SELECT, entry)
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard hovered else { return }
        NSColor.quaternaryLabelColor.withAlphaComponent(0.12).setFill()
        bounds.fill()
    }

    override func mouseEntered(with event: NSEvent) { hovered = true }
    override func mouseExited(with event: NSEvent) { hovered = false }

    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            actions.openWindow(entry)
        } else if event.clickCount == 1 {
            actions.click(PE_CONVERSATION_CLICK_SELECT, entry)
        }
    }

    override func mouseDown(with event: NSEvent) {}

    @objc private func arrowClicked() {
        actions.click(PE_CONVERSATION_CLICK_TOGGLE, entry)
    }

    func picture(_ pictures: ListPictures?, scale: CGFloat) {
        guard entry.picture != 0, face.image == nil else { return }
        face.image = pictures?.image(entry.picture, points: 22, scale: scale)
    }
}

/// A menu item that runs a closure (a frame's More menu)
final class ClosureMenuItem: NSMenuItem {
    private let run: () -> Void

    init(title: String, run: @escaping () -> Void) {
        self.run = run
        super.init(title: title, action: #selector(chosen), keyEquivalent: "")
        target = self
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func chosen() { run() }
}
