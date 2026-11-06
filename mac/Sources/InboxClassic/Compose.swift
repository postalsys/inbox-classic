// The window a message is written in: the address fields, a format bar and the HTML editor (Editor.swift). The fields
// go to the core as typed and the editor's HTML as it comes: the core parses and checks the recipients, sanitizes the
// HTML, adds the quoted message, reads the attached files and builds the message, so this file only edits.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

/// Whether the compose windows let the app quit: all closed, some saving first, or one kept open
enum ComposeClose {
    case closed, saving, kept
}

// ---- the format bar ----

/// The format bar of a window that writes formatted text (the compose window, the signature editor): font, size, then
/// the buttons, which the page's state keeps pressed or not
@MainActor
final class FormatBar: NSObject {
    let view: NSStackView
    private let editor: () -> Editor?
    private let font = NSPopUpButton(frame: .zero, pullsDown: false)
    private let size = NSPopUpButton(frame: .zero, pullsDown: false)
    private var stateButtons: [NSButton] = []
    /// what the Link button does: the window's Link dialog
    var editLink: () -> Void = {}
    /// what the Picture button does
    var insertPicture: () -> Void = {}

    static let fonts = ["Arial", "Arial Black", "Comic Sans MS", "Courier New", "Georgia", "Helvetica", "Tahoma", "Times New Roman",
                        "Trebuchet MS", "Verdana"]
    /// the sizes of <font size>, 1 to 7, in points
    static let sizes = ["8", "10", "12", "14", "18", "24", "36"]

    init(editor: @escaping () -> Editor?) {
        self.editor = editor
        view = NSStackView()
        super.init()
        font.addItems(withTitles: FormatBar.fonts)
        font.target = self
        font.action = #selector(fontChosen)
        font.setAccessibilityIdentifier("format.font")
        size.addItems(withTitles: FormatBar.sizes)
        size.selectItem(at: 1)
        size.target = self
        size.action = #selector(sizeChosen)
        size.setAccessibilityIdentifier("format.size")
        var views: [NSView] = [font, size]
        // the buttons whose state the page reports, in the order of its flags (STATE in editor.js)
        let toggles: [(String, String, String)] = [
            ("text_bold", "bold", "Bold (\u{2318}B)"), ("text_italic", "italic", "Italic (\u{2318}I)"),
            ("text_underline", "underline", "Underline (\u{2318}U)"),
        ]
        let lists: [(String, String, String)] = [
            ("text_number_list_ltr", "insertOrderedList", "Numbered List"), ("text_bullet_list_ltr", "insertUnorderedList", "Bulleted List"),
        ]
        let aligns: [(String, String, String)] = [
            ("text_align_left", "justifyLeft", "Align Left"), ("text_align_center", "justifyCenter", "Center"),
            ("text_align_right", "justifyRight", "Align Right"),
        ]
        for (icon, command, tip) in toggles {
            views.append(stateButton(icon, command, tip))
        }
        views.append(plainButton("text_color", tip: "Font Color", action: #selector(chooseColor)))
        views.append(gap())
        for (icon, command, tip) in lists {
            views.append(stateButton(icon, command, tip))
        }
        views.append(commandButton("text_indent_decrease_ltr", "outdent", "Decrease Indent"))
        views.append(commandButton("text_indent_increase_ltr", "indent", "Increase Indent"))
        views.append(gap())
        for (icon, command, tip) in aligns {
            views.append(stateButton(icon, command, tip))
        }
        views.append(gap())
        views.append(plainButton("link", tip: "Hyperlink (\u{2318}K)", action: #selector(linkClicked)))
        views.append(commandButton("line_horizontal_1", "insertHorizontalRule", "Insert Horizontal Line"))
        views.append(plainButton("image", tip: "Insert Picture", action: #selector(pictureClicked)))
        views.forEach { view.addArrangedSubview($0) }
        view.spacing = 2
        view.setCustomSpacing(8, after: size)
    }

    private func gap() -> NSView {
        let gap = NSView()
        gap.widthAnchor.constraint(equalToConstant: 8).isActive = true
        return gap
    }

    private func button(_ icon: String, tip: String) -> NSButton {
        let button = NSButton(image: Icons.format(icon) ?? NSImage(), target: self, action: nil)
        button.bezelStyle = .toolbar
        button.toolTip = tip
        button.setAccessibilityLabel(tip)
        button.setAccessibilityIdentifier("format.\(icon)")
        return button
    }

    private func plainButton(_ icon: String, tip: String, action: Selector) -> NSButton {
        let made = button(icon, tip: tip)
        made.action = action
        return made
    }

    private func commandButton(_ icon: String, _ command: String, _ tip: String) -> NSButton {
        let made = button(icon, tip: tip)
        made.action = #selector(runCommand(_:))
        made.identifier = NSUserInterfaceItemIdentifier(command)
        return made
    }

    private func stateButton(_ icon: String, _ command: String, _ tip: String) -> NSButton {
        let made = commandButton(icon, command, tip)
        made.setButtonType(.pushOnPushOff)
        stateButtons.append(made)
        return made
    }

    @objc private func runCommand(_ sender: NSButton) {
        guard let command = sender.identifier?.rawValue else { return }
        editor()?.exec(command)
    }

    @objc private func fontChosen() {
        editor()?.exec("fontName", font.titleOfSelectedItem ?? "Arial")
    }

    @objc private func sizeChosen() {
        editor()?.exec("fontSize", "\(size.indexOfSelectedItem + 1)")
    }

    @objc private func chooseColor() {
        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(colorChosen(_:)))
        panel.showsAlpha = false
        panel.orderFront(nil)
    }

    @objc private func colorChosen(_ panel: NSColorPanel) {
        guard let color = panel.color.usingColorSpace(.sRGB) else { return }
        let hex = String(format: "#%02x%02x%02x", Int(color.redComponent * 255), Int(color.greenComponent * 255),
                         Int(color.blueComponent * 255))
        editor()?.exec("foreColor", hex)
    }

    @objc private func linkClicked() {
        editLink()
    }

    @objc private func pictureClicked() {
        insertPicture()
    }

    /// the pressed state of the buttons, from the page's flags
    func showState(_ flags: String) {
        for (button, flag) in zip(stateButtons, flags) {
            button.state = flag == "1" ? .on : .off
        }
    }
}

/// a link address the Link dialog takes: a web address or an e-mail link, with more than the scheme
private func validLink(_ url: String) -> Bool {
    let lower = url.lowercased()
    guard let colon = lower.firstIndex(of: ":"), ["http", "https", "mailto"].contains(String(lower[..<colon])) else { return false }
    return lower[lower.index(after: colon)...].contains { $0 != "/" }
}

/// the Link button and Command-K: a new link on the selection, or with the cursor in a link its address to change, or
/// to empty to take the link off
@MainActor
func insertLink(_ editor: Editor) {
    let current = editor.caretLink
    let editing = !current.isEmpty
    let error = "Type a web address (https://...) or an e-mail link (mailto:...)."
    guard let fields = formDialog(
        title: editing ? "Edit Hyperlink" : "Hyperlink",
        intro: editing ? "Where the link goes. Empty the address to remove the link and keep its text." : "The address the selected text links to.",
        fields: [FormField(label: "Address:", value: editing ? current : "https://")],
        validate: { values in
            let url = values[0].value
            // an emptied address takes the link off
            return (editing && url.isEmpty) || validLink(url) ? nil : error
        })
    else { return }
    editor.link(fields[0].value)
}

/// the picture file at `url` put in the text at the cursor; false when it is no picture the core takes
@MainActor
func insertPictureFile(_ editor: Editor, _ url: URL) -> Bool {
    // the core reads the file and checks that it is a picture
    guard let uri = url.path.withCString({ taken(pe_picture_uri($0)) }) else { return false }
    editor.exec("insertImage", uri)
    return true
}

@MainActor
func insertPicture(_ editor: Editor) {
    guard let file = openFilesPanel(title: "Insert Picture", types: [.png, .jpeg, .gif], multiple: false).first else { return }
    if !insertPictureFile(editor, file) {
        inform("This file is not a PNG, JPEG or GIF picture, or it is larger than 10 MB.", title: "Insert Picture", style: .warning)
    }
}

// ---- the compose window ----

@MainActor
final class ComposeWindow: NSObject, NSWindowDelegate, NSTextFieldDelegate, NSTokenFieldDelegate {
    /// the compose windows open, in the order they opened
    static private(set) var open: [ComposeWindow] = []

    let window: NSWindow
    private let core: Core
    private var account: Int64
    private var editor: Editor!
    private var formatBar: FormatBar!
    private let status = NSTextField(labelWithString: "")
    private var statusText = ""
    private let from = NSPopUpButton(frame: .zero, pullsDown: false)
    private var fromAccounts: [Int64] = []
    let to = AddressField()
    let cc = AddressField()
    let bcc = AddressField()
    let subject = NSTextField(string: "")
    private let attached = WrappingTokenField()
    /// the field editor of To, Cc and Bcc
    fileprivate lazy var addressEditor: AddressEditor = {
        let editor = AddressEditor()
        editor.isFieldEditor = true
        return editor
    }()
    private let ccButton = NSButton(title: "Cc", target: nil, action: nil)
    private let bccButton = NSButton(title: "Bcc", target: nil, action: nil)
    private var rows: [NSGridRow] = []
    private let grid = NSGridView()
    private var inReplyTo = ""
    private var references = ""
    private var quote = ""
    /// the quoted message was plain text: with nothing formatted written, the message goes as plain text
    private var quotePlain = false
    private var quoteText = ""
    /// the attached files, with what the Attach row shows for each: the name and the size when it was added
    private var files: [(url: URL, label: String)] = []
    /// the names of the attached files, for the UI test
    var attachedNames: [String] { files.map { $0.url.lastPathComponent } }
    /// the Message-ID of the draft saved in Drafts, empty before the first save
    private(set) var messageId = ""
    /// the account whose Drafts has that copy, 0 before the first save
    private var draftAccount: Int64 = 0
    private enum Pending {
        case none, send, save, saveAndClose
    }
    private var pending = Pending.none
    private var quoteState = EditorQuote.folded
    private var editedQuote = ""
    /// something was typed: closing asks first
    private var dirty = false
    private var filling = true

    /// opens a compose window from `account`, with `draft` (a reply, a forward, a saved draft, a mailto: link)
    @discardableResult
    static func open(core: Core, account: Int64, draft: Draft?) -> ComposeWindow {
        let window = ComposeWindow(core: core, account: account, draft: draft?.info?.pointee)
        open.append(window)
        window.window.makeKeyAndOrderFront(nil)
        return window
    }

    private init(core: Core, account: Int64, draft: PeDraftInfo?) {
        self.core = core
        self.account = account
        let title = draft.map { text($0.subject) }.flatMap { $0.isEmpty ? nil : $0 } ?? "New Message"
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 620),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier("compose")
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        super.init()
        window.delegate = self
        makeToolbar()
        fillFrom()
        if let draft {
            to.stringValue = text(draft.to)
            cc.stringValue = text(draft.cc)
            bcc.stringValue = text(draft.bcc)
            subject.stringValue = text(draft.subject)
            inReplyTo = text(draft.in_reply_to)
            references = text(draft.references)
            quote = text(draft.quote)
            quoteText = text(draft.quote_text)
            quotePlain = draft.quote_text != nil
            // a saved draft opened again: its files, and its Message-ID so the next save replaces it
            messageId = text(draft.message_id)
            draftAccount = account
            for index in 0..<draft.attachment_count {
                if let path = draft.attachments[index] {
                    addFile(URL(fileURLWithPath: String(cString: path)))
                }
            }
        }
        makeEditor(draft)
        window.contentView = layout(showCc: !cc.stringValue.isEmpty, showBcc: !bcc.stringValue.isEmpty)
        // files dropped from the Finder are attached
        window.contentView?.registerForDraggedTypes([.fileURL])
        (window.contentView as? DropView)?.dropped = { [weak self] in self?.addFiles($0) }
        showFiles()
        filling = false
        if !TestHooks.testing {
            window.setFrameAutosaveName("Compose")
        }
        if TestHooks.testing || !window.setFrameUsingName("Compose") {
            window.center()
        }
        let offset = CGFloat(ComposeWindow.open.count) * 22
        window.setFrameOrigin(NSPoint(x: window.frame.minX + offset, y: window.frame.minY - offset))
        // the cursor where the user writes: the top of the reply, or the To field of a new message
        if let draft, !text(draft.to).isEmpty {
            after(0.3) { [weak self] in self?.editor.focus() }
        } else {
            window.initialFirstResponder = to
        }
    }

    private func layout(showCc: Bool, showBcc: Bool) -> NSView {
        from.setAccessibilityIdentifier("compose.from")
        from.target = self
        from.action = #selector(chooseFrom)
        for (field, id) in [(to, "compose.to"), (cc, "compose.cc"), (bcc, "compose.bcc")] {
            field.core = core
            field.setAccessibilityIdentifier(id)
            field.delegate = self
        }
        subject.setAccessibilityIdentifier("compose.subject")
        subject.delegate = self
        attached.setAccessibilityIdentifier("compose.attached")
        attached.delegate = self
        attached.tokenStyle = .rounded
        attached.isEditable = true
        // every attached file in sight: the row grows a line for what does not fit, as a forward of several has
        attached.usesSingleLineMode = false
        attached.cell?.wraps = true
        attached.cell?.isScrollable = false
        attached.lineBreakMode = .byWordWrapping
        // Cc and Bcc wait behind these until needed, as most mail programs have it now
        ccButton.target = self
        ccButton.action = #selector(showCcRow)
        ccButton.setAccessibilityIdentifier("compose.show-cc")
        bccButton.target = self
        bccButton.action = #selector(showBccRow)
        bccButton.setAccessibilityIdentifier("compose.show-bcc")
        for button in [ccButton, bccButton] {
            button.bezelStyle = .push
            button.controlSize = .small
        }
        let toRow = NSStackView(views: [to, ccButton, bccButton])
        to.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let label = { (text: String) -> NSTextField in
            let label = NSTextField(labelWithString: text)
            label.alignment = .right
            return label
        }
        grid.addRow(with: [label("From:"), from])
        grid.addRow(with: [label("To:"), toRow])
        grid.addRow(with: [label("Cc:"), cc])
        grid.addRow(with: [label("Bcc:"), bcc])
        grid.addRow(with: [label("Subject:"), subject])
        grid.addRow(with: [label("Attach:"), attached])
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 0).width = 64
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 6
        grid.row(at: 2).isHidden = !showCc
        grid.row(at: 3).isHidden = !showBcc
        ccButton.isHidden = showCc
        bccButton.isHidden = showBcc
        for row in 1..<6 {
            grid.cell(atColumnIndex: 1, rowIndex: row).xPlacement = .fill
        }
        status.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byTruncatingTail
        status.setAccessibilityIdentifier("compose.status")
        let editorView = editor.view
        let content = DropView()
        for view in [grid, formatBar.view, editorView, status] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 10),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
            formatBar.view.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 10),
            formatBar.view.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            formatBar.view.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -10),
            editorView.topAnchor.constraint(equalTo: formatBar.view.bottomAnchor, constant: 6),
            editorView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: status.topAnchor, constant: -4),
            status.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            status.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            status.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -5),
            status.heightAnchor.constraint(equalToConstant: 16),
        ])
        window.setContentBorderThickness(26, for: .minY)
        return content
    }

    @objc private func showCcRow() {
        grid.row(at: 2).isHidden = false
        ccButton.isHidden = true
        window.makeFirstResponder(cc)
    }

    @objc private func showBccRow() {
        grid.row(at: 3).isHidden = false
        bccButton.isHidden = true
        window.makeFirstResponder(bcc)
    }

    // ---- the toolbar ----

    private func makeToolbar() {
        let toolbar = NSToolbar(identifier: "Compose")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        window.toolbar = toolbar
        window.toolbarStyle = .expanded
    }

    // ---- From ----

    /// the From list: each account as "Name <address>", the one the message goes from selected
    private func fillFrom() {
        for (index, account) in core.accounts().enumerated() {
            from.addItem(withTitle: account.label)
            fromAccounts.append(account.id)
            if account.id == self.account {
                from.selectItem(at: index)
            }
        }
    }

    /// another account chosen in From: the message goes from it, with its servers, Sent Items and Drafts
    @objc private func chooseFrom() {
        let chosen = from.indexOfSelectedItem
        guard fromAccounts.indices.contains(chosen), fromAccounts[chosen] != account else { return }
        account = fromAccounts[chosen]
        // its signature in place of the other's
        editor.signature(taken(pe_signature_block(core.handle, account)) ?? "")
        changed()
    }

    // ---- the editor ----

    private func makeEditor(_ draft: PeDraftInfo?) {
        // a saved draft opened again goes on with what was written; anything new starts with the account's signature
        let saved = draft.map { !text($0.message_id).isEmpty } ?? false
        var body = draft.map { text($0.body) } ?? ""
        if !saved, let signature = taken(pe_signature_block(core.handle, account)) {
            body += signature
        }
        let page = taken(body.withCString { body in
            draft?.quote.map { pe_editor_document($0, draft!.quote_folded, body) } ?? pe_editor_document(nil, false, body)
        }) ?? ""
        var handlers = Editor.Handlers()
        handlers.html = { [weak self] html, quote, edited in
            // outside the web view's callback that brought it
            onMain { self?.htmlArrived(html, quote: quote, edited: edited) }
        }
        handlers.state = { [weak self] in self?.formatBar.showState($0) }
        handlers.dirty = { [weak self] in self?.changed() }
        handlers.send = { [weak self] in self?.request(.send) }
        handlers.save = { [weak self] in self?.request(.save) }
        handlers.dropped = { [weak self] in self?.dropOnText($0) }
        handlers.link = { [weak self] in self?.showLink($0) }
        handlers.editLink = { [weak self] in
            guard let self else { return }
            insertLink(editor)
        }
        editor = Editor(document: page, handlers: handlers)
        formatBar = FormatBar { [weak self] in self?.editor }
        formatBar.editLink = { [weak self] in
            guard let self else { return }
            insertLink(editor)
        }
        formatBar.insertPicture = { [weak self] in
            guard let self else { return }
            insertPicture(editor)
        }
    }

    /// files dropped on the text: each picture goes in where they were dropped; other files (and pictures too large to
    /// go inline) are attached
    private func dropOnText(_ urls: [URL]) {
        let attach = urls.filter { !insertPictureFile(editor, $0) }
        if !attach.isEmpty {
            addFiles(attach)
        }
    }

    // ---- the status bar ----

    private func setStatus(_ text: String) {
        statusText = text
        status.stringValue = text
    }

    /// where the link under the mouse, or else the one the cursor is in, goes; the status as it was without either
    private func showLink(_ link: String) {
        status.stringValue = link.isEmpty ? statusText : "\(link)    (\u{2318}-click to open)"
    }

    /// the message changed since it was sent to Drafts or opened: a "saved" status no longer holds
    private func changed() {
        if !dirty && !filling {
            setStatus("")
        }
        dirty = true
    }

    func controlTextDidChange(_ notification: Notification) {
        if !filling {
            changed()
        }
        (notification.object as? AddressField)?.typed(notification)
    }

    // ---- the attached files ----

    /// adds a file that is there (not a folder); false otherwise
    @discardableResult
    private func addFile(_ url: URL) -> Bool {
        var folder: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &folder), !folder.boolValue else { return false }
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? UInt64 ?? 0
        files.append((url, "\(url.lastPathComponent) (\(formatSize(size)))"))
        return true
    }

    func addFiles(_ urls: [URL]) {
        for url in urls where addFile(url) {
            changed()
        }
        showFiles()
    }

    /// the attached files in the Attach row; the row is there only with files
    private func showFiles() {
        attached.objectValue = files.map(\.label)
        if grid.numberOfRows > 5 {
            grid.row(at: 5).isHidden = files.isEmpty
        }
    }

    @objc private func attach() {
        addFiles(openFilesPanel(title: "Insert Attachment"))
    }

    /// a file taken off in the Attach row (Delete, or Remove in its menu)
    func controlTextDidEndEditing(_ notification: Notification) {
        syncFilesFromTokens()
    }

    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        // only the files attached are there, nothing typed
        []
    }

    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        true
    }

    func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
        let menu = NSMenu()
        let item = NSMenuItem(title: "Remove", action: #selector(removeFile(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = representedObject
        menu.addItem(item)
        return menu
    }

    @objc private func removeFile(_ sender: NSMenuItem) {
        guard let label = sender.representedObject as? String, let index = files.firstIndex(where: { $0.label == label }) else { return }
        files.remove(at: index)
        changed()
        showFiles()
    }

    private func syncFilesFromTokens() {
        let left = attached.objectValue as? [String] ?? []
        if left.count != files.count {
            files = files.filter { left.contains($0.label) }
            changed()
            showFiles()
        }
    }

    // ---- sending and saving ----

    /// the editor's HTML is asked for first, the action follows when it comes
    private func request(_ action: Pending) {
        if pending == .none {
            syncFilesFromTokens()
            pending = action
            editor.requestHtml()
        }
    }

    private func htmlArrived(_ html: String, quote state: EditorQuote, edited: String) {
        quoteState = state
        editedQuote = edited
        let action = pending
        pending = .none
        switch action {
        case .send: send(html)
        case .save: save(html, close: false)
        case .saveAndClose: save(html, close: true)
        case .none: break
        }
    }

    /// the message as the core takes it, from the fields and the editor's HTML; it points into `strings`
    private func outgoing(_ html: String, _ strings: CStrings) -> PeOutgoing {
        // the draft's quote while folded, the user's once unfolded, none once deleted; its plain text only for the draft's
        let folded = quoteState == .folded
        let quoted = folded ? quote : editedQuote
        return PeOutgoing(
            to: strings.add(to.stringValue), cc: strings.add(cc.stringValue), bcc: strings.add(bcc.stringValue),
            subject: strings.add(subject.stringValue), text: nil, html: strings.add(html),
            quote: quoted.isEmpty || quoteState == .removed ? nil : strings.add(quoted),
            in_reply_to: strings.optional(inReplyTo), references: strings.add(references),
            attachments: strings.array(files.map(\.url.path)), attachment_count: files.count,
            message_id: strings.optional(messageId),
            // saved in another account's Drafts before From changed: the core moves it once this account has it
            draft_account: draftAccount != account ? draftAccount : 0,
            quote_plain: quotePlain, quote_text: folded && !quoteText.isEmpty ? strings.add(quoteText) : nil)
    }

    /// sends with the HTML the editor gave, now or with the next Send/Recv
    private func send(_ html: String) {
        let strings = CStrings()
        var message = outgoing(html, strings)
        var reason: UnsafeMutablePointer<CChar>?
        guard pe_message_send(core.handle, account, &message, &reason) else {
            // a typo in an address or a file that is gone: the message stays open to fix it
            inform(taken(reason) ?? "The message could not be sent.", style: .warning)
            return
        }
        // the main window shows whether the server took it
        dirty = false
        closeNow()
    }

    /// saves in Drafts with the HTML the editor gave, in place of the copy saved before; closes the window after when
    /// `close`
    private func save(_ html: String, close: Bool) {
        let strings = CStrings()
        var message = outgoing(html, strings)
        var id: UnsafeMutablePointer<CChar>?
        var reason: UnsafeMutablePointer<CChar>?
        guard pe_draft_save(core.handle, account, &message, &id, &reason) else {
            inform(taken(reason) ?? "The message could not be saved.", style: .warning)
            // not closing after all: the app does not wait for it
            if close {
                AppDelegate.shared.quitAfterCompose = false
            }
            return
        }
        draftAccount = account
        messageId = taken(id) ?? ""
        dirty = false
        editor.clean()
        // the server's answer follows (draftSaved)
        setStatus("Saving to Drafts\u{2026}")
        if close {
            closeNow()
        }
    }

    @objc func sendClicked() { request(.send) }
    @objc private func saveClicked() { request(.save) }

    // ---- closing ----

    /// whether the window may close now: when nothing changed since it was sent or saved, or the user does not want
    /// it saved. Save saves it in Drafts and closes the window after.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard dirty else { return true }
        switch askYesNoCancel("Do you want to save changes to this message in Drafts?", yes: "Save", no: "Don't Save") {
        case .yes:
            request(.saveAndClose)
            return false
        case .no:
            return true
        case .cancel:
            return false
        }
    }

    func windowWillClose(_ notification: Notification) {
        editor.close()
        ComposeWindow.open.removeAll { $0 === self }
        AppDelegate.shared?.composeClosed()
        // back to the main window, as when it was the owner
        if NSApp.keyWindow == nil || NSApp.keyWindow === window {
            AppDelegate.shared?.main?.window.makeKeyAndOrderFront(nil)
        }
    }

    private func closeNow() {
        window.delegate?.windowWillClose?(Notification(name: NSWindow.willCloseNotification, object: window))
        window.delegate = nil
        window.orderOut(nil)
        window.close()
    }

    /// closes every compose window, each asking about its changes
    static func closeAll() -> ComposeClose {
        var saving = false
        for compose in open {
            if compose.windowShouldClose(compose.window) {
                compose.dirty = false
                compose.closeNow()
                continue
            }
            // still open: saving before it closes (Save), or kept open (Cancel), which keeps the app too
            guard compose.pending == .saveAndClose else { return .kept }
            saving = true
        }
        return saving ? .saving : .closed
    }

    /// the server's answer to a save: the window that saved it says so; false when no window has that draft
    static func draftSaved(messageId: String, problem: String) -> Bool {
        guard !messageId.isEmpty, let compose = open.first(where: { $0.messageId == messageId }) else { return false }
        compose.setStatus(problem.isEmpty ? "Saved in Drafts at \(timeNow())" : "Not saved in Drafts: \(problem)")
        return true
    }
}

extension ComposeWindow: NSToolbarDelegate {
    private static let items: [(String, String, String, Selector)] = [
        ("send", "Send", "send", #selector(sendClicked)), ("save", "Save", "save", #selector(saveClicked)),
        ("attach", "Attach", "attach", #selector(attach)),
    ]

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [NSToolbarItem.Identifier("send"), .space, NSToolbarItem.Identifier("save"), .space, NSToolbarItem.Identifier("attach")]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let (_, label, icon, action) = ComposeWindow.items.first(where: { $0.0 == identifier.rawValue }) else { return nil }
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.toolTip = label
        item.image = Icons.toolbar(icon)
        item.target = self
        item.action = action
        item.isBordered = true
        return item
    }
}

/// The content of the compose window: files dropped on it are attached
final class DropView: NSView {
    var dropped: ([URL]) -> Void = { _ in }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        dropped(urls)
        return !urls.isEmpty
    }
}

// ---- address completion ----

/// The To, Cc and Bcc fields: the address being typed (between the commas around the cursor) is looked up in the
/// core's address book, and the people found are offered under it, the system's completion list
final class AddressField: NSTextField {
    var core: Core?
    private var completing = false

    /// typed in: the list of people for what is typed now
    @MainActor
    func typed(_ notification: Notification) {
        guard !completing, let editor = currentEditor() as? NSTextView,
              let event = NSApp.currentEvent, event.type == .keyDown,
              let characters = event.characters, !characters.isEmpty,
              characters.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) && $0 != "\u{7f}" })
        else { return }
        completing = true
        editor.complete(nil)
        completing = false
    }

    /// the address the cursor is in: from after the comma before it to the cursor, without the spaces before it
    static func tokenRange(_ text: NSString, caret: Int) -> NSRange {
        var start = caret
        while start > 0, ![",", ";"].contains(text.substring(with: NSRange(location: start - 1, length: 1))) {
            start -= 1
        }
        while start < caret, text.substring(with: NSRange(location: start, length: 1)) == " " {
            start += 1
        }
        return NSRange(location: start, length: caret - start)
    }

    /// the people for `typed`, as the core finds them
    @MainActor
    func people(_ typed: String) -> [String] {
        // a whole address typed with its brackets is not looked up again
        guard let core, !typed.isEmpty, !typed.contains("<") else { return [] }
        guard let list = typed.withCString({ pe_contacts(core.handle, $0, 8) }) else { return [] }
        defer { pe_contact_list_free(list) }
        return (0..<pe_contact_list_count(list)).compactMap { pe_contact_list_get(list, $0).map { text($0.pointee.label) } }
    }
}

extension ComposeWindow {
    func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange range: NSRange,
                 indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        guard let field = control as? AddressField else { return [] }
        // the best one chosen: Return or Tab takes it
        index.pointee = 0
        return field.people((textView.string as NSString).substring(with: range))
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        // Return or Tab after a person shown in full at the end: a comma and a space wait for the next one
        guard control is AddressField,
              selector == #selector(NSResponder.insertNewline(_:)) || selector == #selector(NSResponder.insertTab(_:)) else { return false }
        let text = textView.string
        guard text.hasSuffix(">"), NSMaxRange(textView.selectedRange()) >= (text as NSString).length else { return false }
        textView.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
        textView.insertText(", ", replacementRange: textView.selectedRange())
        return selector == #selector(NSResponder.insertNewline(_:))
    }

    /// the address fields edit with an editor that completes whole addresses
    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        guard client is AddressField else { return nil }
        return addressEditor
    }
}

/// The field editor of the address fields: what is completed is the address the cursor is in (between the commas), not
/// the word, and a person taken at the end gets a comma and a space for the next one
final class AddressEditor: NSTextView {
    override var rangeForUserCompletion: NSRange {
        AddressField.tokenRange(string as NSString, caret: selectedRange().location)
    }

    override func insertCompletion(_ word: String, forPartialWordRange range: NSRange, movement: Int, isFinal flag: Bool) {
        let taken = flag && (movement == NSTextMovement.return.rawValue || movement == NSTextMovement.tab.rawValue)
        let atEnd = NSMaxRange(range) >= (string as NSString).length
        super.insertCompletion(word + (taken && atEnd ? ", " : ""), forPartialWordRange: range, movement: movement, isFinal: flag)
    }
}

// ---- the signature editor ----

/// The signature of an account, written with the same editor and format bar as a message
@MainActor
final class SignatureEditor: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let core: Core
    private let account: Int64
    private var editor: Editor!
    private var formatBar: FormatBar!
    private var saving = false
    private var saved = false

    @discardableResult
    static func edit(core: Core, account: Int64, name: String) -> Bool {
        guard let current = taken(pe_account_signature(core.handle, account)) else { return false }
        let editor = SignatureEditor(core: core, account: account, name: name, current: current)
        return editor.run()
    }

    private init(core: Core, account: Int64, name: String, current: String) {
        self.core = core
        self.account = account
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 360), styleMask: [.titled, .resizable], backing: .buffered,
                          defer: true)
        window.title = "Signature - \(name)"
        window.identifier = NSUserInterfaceItemIdentifier("signature")
        super.init()
        var handlers = Editor.Handlers()
        handlers.html = { [weak self] html, _, _ in
            onMain { self?.htmlArrived(html) }
        }
        handlers.state = { [weak self] in self?.formatBar.showState($0) }
        handlers.save = { [weak self] in self?.ok() }
        handlers.dropped = { [weak self] urls in
            guard let self else { return }
            // pictures go in where they were dropped; a signature has no attachments
            urls.forEach { _ = insertPictureFile(self.editor, $0) }
        }
        handlers.editLink = { [weak self] in
            guard let self else { return }
            insertLink(editor)
        }
        editor = Editor(document: current.withCString { taken(pe_editor_document(nil, false, $0)) } ?? "", handlers: handlers)
        formatBar = FormatBar { [weak self] in self?.editor }
        formatBar.editLink = { [weak self] in
            guard let self else { return }
            insertLink(editor)
        }
        formatBar.insertPicture = { [weak self] in
            guard let self else { return }
            insertPicture(editor)
        }
        let hint = NSTextField(labelWithString: "Added to new messages, replies and forwards from this account.")
        hint.textColor = .secondaryLabelColor
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        let okButton = NSButton(title: "OK", target: self, action: #selector(ok))
        okButton.keyEquivalent = "\r"
        okButton.keyEquivalentModifierMask = .command
        okButton.setAccessibilityIdentifier("signature.ok")
        let bottom = NSStackView(views: [hint, NSView(), cancel, okButton])
        let content = NSView()
        for view in [formatBar.view, editor.view, bottom] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        NSLayoutConstraint.activate([
            formatBar.view.topAnchor.constraint(equalTo: content.topAnchor, constant: 10),
            formatBar.view.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            editor.view.topAnchor.constraint(equalTo: formatBar.view.bottomAnchor, constant: 6),
            editor.view.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            editor.view.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
            editor.view.bottomAnchor.constraint(equalTo: bottom.topAnchor, constant: -10),
            bottom.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            bottom.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
            bottom.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -10),
        ])
        window.contentView = content
        window.delegate = self
    }

    @objc private func ok() {
        // the page's HTML first; it is saved when it comes
        if !saving {
            saving = true
            editor.requestHtml()
        }
    }

    private func htmlArrived(_ html: String) {
        saved = html.withCString { pe_account_set_signature(core.handle, account, $0) }
        guard saved else {
            inform("The signature could not be saved.", title: "Signature", style: .error)
            saving = false
            return
        }
        NSApp.stopModal()
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    func run() -> Bool {
        window.center()
        Modal.opened(window)
        after(0.3) { [weak self] in self?.editor.focus() }
        NSApp.runModal(for: window)
        Modal.closed(window)
        editor.close()
        window.orderOut(nil)
        return saved
    }
}

/// A token field as tall as its tokens need at its width, so a row of attachments wraps instead of hiding the last ones
final class WrappingTokenField: NSTokenField {
    private var laidOutWidth: CGFloat = 0

    override var intrinsicContentSize: NSSize {
        guard let cell, bounds.width > 0 else { return super.intrinsicContentSize }
        let needed = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: bounds.width, height: .greatestFiniteMagnitude))
        return NSSize(width: NSView.noIntrinsicMetric, height: max(ceil(needed.height), super.intrinsicContentSize.height))
    }

    override func layout() {
        super.layout()
        if laidOutWidth != bounds.width {
            laidOutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    override var objectValue: Any? {
        didSet { invalidateIntrinsicContentSize() }
    }
}
