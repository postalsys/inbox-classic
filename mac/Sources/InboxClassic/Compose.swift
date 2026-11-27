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
            ("text_bold", "bold", Text.macBold.text + " (\u{2318}B)"), ("text_italic", "italic", Text.macItalic.text + " (\u{2318}I)"),
            ("text_underline", "underline", Text.macUnderline.text + " (\u{2318}U)"),
        ]
        let lists: [(String, String, String)] = [
            ("text_number_list_ltr", "insertOrderedList", Text.uiFormatNumbers.text),
            ("text_bullet_list_ltr", "insertUnorderedList", Text.uiFormatBullets.text),
        ]
        let aligns: [(String, String, String)] = [
            ("text_align_left", "justifyLeft", Text.uiFormatLeft.text), ("text_align_center", "justifyCenter", Text.uiFormatCenter.text),
            ("text_align_right", "justifyRight", Text.uiFormatRight.text),
        ]
        for (icon, command, tip) in toggles {
            views.append(stateButton(icon, command, tip))
        }
        views.append(plainButton("text_color", tip: Text.uiFormatColor.text, action: #selector(chooseColor)))
        views.append(gap())
        for (icon, command, tip) in lists {
            views.append(stateButton(icon, command, tip))
        }
        views.append(commandButton("text_indent_decrease_ltr", "outdent", Text.uiFormatOutdent.text))
        views.append(commandButton("text_indent_increase_ltr", "indent", Text.uiFormatIndent.text))
        views.append(gap())
        for (icon, command, tip) in aligns {
            views.append(stateButton(icon, command, tip))
        }
        views.append(gap())
        views.append(plainButton("link", tip: Text.uiHyperlink.text + " (\u{2318}K)", action: #selector(linkClicked)))
        views.append(commandButton("line_horizontal_1", "insertHorizontalRule", Text.uiFormatLine.text))
        views.append(plainButton("image", tip: Text.uiInsertPicture.text, action: #selector(pictureClicked)))
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
        // a picture only: without AppKit's "Button" as its title, which VoiceOver could read
        button.title = ""
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
    let error = Text.uiLinkInvalid.text
    guard let fields = formDialog(
        title: editing ? Text.uiEditHyperlink.text : Text.uiHyperlink.text,
        intro: editing ? Text.uiEditHyperlinkIntro.text : Text.uiHyperlinkIntro.text,
        fields: [FormField(label: Text.uiLinkAddress.text, value: editing ? current : "https://")],
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
    guard let file = openFilesPanel(title: Text.uiInsertPicture.text, types: [.png, .jpeg, .gif], multiple: false).first
    else { return }
    if !insertPictureFile(editor, file) {
        inform(Text.uiNotAPicture.text, title: Text.uiInsertPicture.text, style: .warning)
    }
}

// ---- the compose window ----

@MainActor
final class ComposeWindow: NSObject, NSWindowDelegate, NSTextFieldDelegate, NSTokenFieldDelegate {
    /// the compose windows open, in the order they opened
    static private(set) var open: [ComposeWindow] = []
    /// the one in front, which the commands of the menus are about: the key window, or while the app is not active
    /// the frontmost window when it is one
    static var key: ComposeWindow? {
        if let key = open.first(where: { $0.window.isKeyWindow }) { return key }
        guard !NSApp.isActive, let front = frontWindow else { return nil }
        return open.first { $0.window === front }
    }

    /// the app's window in front of its others, by the window server's order of every Space: `orderedWindows` keeps
    /// an old order while the app is in the background and not on the Space in use (another app full screen)
    private static var frontWindow: NSWindow? {
        let numbers = NSWindow.windowNumbers(options: [.allSpaces]) ?? []
        return numbers.lazy.compactMap { NSApp.window(withWindowNumber: $0.intValue) }
            .first { $0.isVisible && $0.canBecomeKey }
    }

    let window: NSWindow
    private let core: Core
    private var account: Int64
    private var editor: Editor!
    private var formatBar: FormatBar!
    private let status = NSTextField(labelWithString: "")
    private var statusText = ""
    private let from = NSPopUpButton(frame: .zero, pullsDown: false)
    /// what it can go from, in the order of the From list: an account, and one of its other addresses or "" for its own
    private var fromChoices: [(account: Int64, address: String)] = []
    /// the other address it goes from, "" for the account's own
    private var fromAddress = ""
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
    private let ccButton = NSButton(title: Text.headerCc.text, target: nil, action: nil)
    private let bccButton = NSButton(title: Text.macBcc.text, target: nil, action: nil)
    private let grid = NSGridView()
    /// the rows of the field grid
    private enum Row {
        static let from = 0, fromNote = 1, to = 2, cc = 3, bcc = 4, keys = 5, subject = 6, attach = 7
    }
    /// under From while the account chosen is not signed in or can not connect: the message will wait in the Outbox
    private let fromNote = NSStackView()
    /// what it says, empty while it is hidden (the UI test)
    private(set) var fromNoteText = ""
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
        /// look: only what was written, for whether it still quotes encrypted mail
        case none, look, autosave, send, save, saveAndClose

        /// which wins when the HTML is asked for twice: the user's own action over the automatic save over a look
        var weight: Int {
            switch self {
            case .none: 0
            case .look: 1
            case .autosave: 2
            case .send, .save, .saveAndClose: 3
            }
        }
    }
    private var pending = Pending.none
    private var quoteState = EditorQuote.folded
    private var editedQuote = ""
    /// something was typed: closing asks first
    private var dirty = false
    private var filling = true
    /// changes made, counted: a save leaves the window clean only when nothing changed while it was asked for
    private var changes = 0
    /// the oldest change not saved yet, and the timer that saves it by itself (pe_autosave_wait)
    private var unsavedSince: Date?
    private var autosaveTimer: Timer?
    /// the account has no Drafts folder: the automatic saving stops for this message
    private var autosaveOff = false
    /// the copy in Drafts is one the user kept (saved, or opened from Drafts): closing without saving leaves it there
    private var kept = false
    /// the copy in Drafts was saved automatically since: closing asks about it, and without saving removes it unless
    /// it was kept
    private var autosaved = false

    // signing and encrypting (ComposeSecurity.swift): the user's own Sign, Encrypt, whether it answers or forwards
    // encrypted mail, and what the core says of them now
    private var sign = false
    private var encrypt = false
    private var quoteEncrypted = false
    private(set) var security = ComposeSecurityState()
    /// the lookups of keys this window started: their KeysFound brings what they found
    private var lookups = Set<UInt64>()
    /// the recipients typed: the security asked again once typing stops
    private var recipientsTimer: Timer?
    /// what was written as the editor last gave it: whether it still holds a quote counts while it answers encrypted
    /// mail
    private var lastHtml = ""
    let securityLine = SecurityBar(id: "compose.security")
    /// the line over a draft an AI agent wrote, naming the agent: set when the window opens, kept while it is open
    private let agentNote: String?
    private lazy var agentLine = NoteBar(id: "compose.agentNote", symbol: "sparkles")
    let keysRow = KeyChipsRow()
    private(set) var signButton: NSButton?
    private(set) var encryptButton: NSButton?
    private var signItem: NSToolbarItem?
    private var encryptItem: NSToolbarItem?
    private var formatBarTop: NSLayoutConstraint!
    private var formatBarUnderLine: NSLayoutConstraint!
    /// Recipients' Keys while it is open
    private(set) weak var keysSheet: RecipientKeysSheet?

    /// opens a compose window from `account`, with `draft` (a reply, a forward, a saved draft, a mailto: link)
    @discardableResult
    static func open(core: Core, account: Int64, draft: Draft?) -> ComposeWindow {
        let window = ComposeWindow(core: core, account: account, draft: draft?.info?.pointee, agentNote: draft?.agentNote)
        open.append(window)
        window.window.makeKeyAndOrderFront(nil)
        return window
    }

    private init(core: Core, account: Int64, draft: PeDraftInfo?, agentNote: String?) {
        self.core = core
        self.account = account
        self.agentNote = agentNote
        let title = draft.map { text($0.subject) }.flatMap { $0.isEmpty ? nil : $0 } ?? Text.uiNewMessageTitle.text
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 620),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.autorecalculatesKeyViewLoop = true
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
            kept = !messageId.isEmpty
            // a reply from the address its message was sent to, a draft from the one it was saved with
            selectFrom(text(draft.from))
            // a reply to encrypted mail starts encrypted, a draft as it was saved
            sign = draft.sign
            encrypt = draft.encrypt
            quoteEncrypted = draft.quote_encrypted
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
        if encrypt {
            findKeys()
        }
        refreshSecurity()
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
            // many recipients scroll in the field, never widen the window
            field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            field.core = core
            field.setAccessibilityIdentifier(id)
            field.delegate = self
        }
        subject.setAccessibilityIdentifier("compose.subject")
        subject.delegate = self
        attached.setAccessibilityIdentifier("compose.attached")
        attached.delegate = self
        // the rounded style keeps an empty slot before the name; squared chips start with it
        attached.tokenStyle = .squared
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
        // To, Cc and Bcc are buttons that open Select Recipients, as in Outlook Express
        let pick = { (text: String, index: Int, id: String) -> NSButton in
            let button = NSButton(title: text, target: self, action: #selector(self.pickRecipients(_:)))
            // the regular size, so its words match the labels of the same column
            button.bezelStyle = .push
            button.tag = index
            button.toolTip = Text.uiPickTip.text
            button.setAccessibilityIdentifier(id)
            return button
        }
        let picks = [pick(Text.uiFieldTo.text, 0, "compose.pick.to"), pick(Text.uiFieldCc.text, 1, "compose.pick.cc"),
                     pick(Text.uiFieldBcc.text, 2, "compose.pick.bcc")]
        // one width, so their edges line up
        let pickWidth = picks.map(\.fittingSize.width).max() ?? 0
        for button in picks {
            button.widthAnchor.constraint(equalToConstant: pickWidth).isActive = true
        }
        grid.addRow(with: [label(Text.uiFieldFrom.text), from])
        grid.addRow(with: [NSGridCell.emptyContentView, makeFromNote()])
        grid.addRow(with: [picks[0], toRow])
        grid.addRow(with: [picks[1], cc])
        grid.addRow(with: [picks[2], bcc])
        grid.addRow(with: [label(Text.uiFieldKeys.text), keysRow])
        grid.addRow(with: [label(Text.uiFieldSubject.text), subject])
        grid.addRow(with: [label(Text.uiFieldAttach.text), attached])
        grid.column(at: 0).xPlacement = .trailing
        // as wide as its widest label from the start, so the fields stay put when Attachments or Cc shows
        grid.column(at: 0).width = (0..<grid.numberOfRows)
            .compactMap { grid.cell(atColumnIndex: 0, rowIndex: $0).contentView?.fittingSize.width }.max() ?? 0
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 6
        grid.row(at: Row.cc).isHidden = !showCc
        grid.row(at: Row.bcc).isHidden = !showBcc
        ccButton.isHidden = showCc
        bccButton.isHidden = showBcc
        for row in Row.to...Row.attach {
            grid.cell(atColumnIndex: 1, rowIndex: row).xPlacement = .fill
        }
        grid.row(at: Row.fromNote).rowAlignment = .none
        grid.row(at: Row.fromNote).yPlacement = .center
        showFromNote()
        // the chips are no text: the row's label in the middle of them
        grid.row(at: Row.keys).yPlacement = .center
        grid.row(at: Row.keys).rowAlignment = .none
        grid.row(at: Row.keys).isHidden = true
        keysRow.clicked = { [weak self] in self?.openRecipientKeys() }
        securityLine.details = { [weak self] in self?.openRecipientKeys() }
        status.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byTruncatingTail
        // a long status (the keys a lookup did not find) is cut off, never widens the window
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        status.setAccessibilityIdentifier("compose.status")
        let editorView = editor.view
        let content = DropView()
        for view in [grid, securityLine, formatBar.view, editorView, status] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        // the line of signing and encrypting between the fields and the format bar, from edge to edge as the reading
        // pane's bar; the format bar under the fields while there is none. A draft an agent wrote has its note over
        // both, and they follow it
        let fieldsEnd = placeAgentLine(in: content)
        let underNote = agentNote != nil
        formatBarTop = formatBar.view.topAnchor.constraint(equalTo: fieldsEnd, constant: underNote ? 8 : 10)
        formatBarUnderLine = formatBar.view.topAnchor.constraint(equalTo: securityLine.bottomAnchor, constant: 8)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 10),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
            securityLine.topAnchor.constraint(equalTo: fieldsEnd, constant: underNote ? 0 : 10),
            securityLine.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            securityLine.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            formatBarTop,
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

    /// the agent's note under the fields, from edge to edge, when there is one: where what follows the fields starts
    private func placeAgentLine(in content: NSView) -> NSLayoutYAxisAnchor {
        guard let agentNote else { return grid.bottomAnchor }
        agentLine.text = agentNote
        agentLine.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(agentLine)
        NSLayoutConstraint.activate([
            agentLine.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 10),
            agentLine.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            agentLine.trailingAnchor.constraint(equalTo: content.trailingAnchor),
        ])
        return agentLine.bottomAnchor
    }

    /// To, Cc or Bcc: Select Recipients, what is chosen added to the fields
    @objc private func pickRecipients(_ sender: NSButton) {
        guard let chosen = PeoplePicker(core: core, kind: .recipients).run(on: window) else { return }
        for (index, entries) in chosen.enumerated() where !entries.isEmpty {
            addRecipients(entries.map(\.label).filter { !$0.isEmpty }.joined(separator: ", "), field: index)
        }
    }

    /// `labels` (people and groups as they go in an address field) added to To (0), Cc (1) or Bcc (2), each address
    /// once; Cc and Bcc shown when they get some
    func addRecipients(_ labels: String, field index: Int) {
        guard !labels.isEmpty else { return }
        let field = [to, cc, bcc][index]
        field.stringValue = addressFieldAdding(field.stringValue, labels)
        if index > 0 {
            grid.row(at: Row.to + index).isHidden = false
            (index == 1 ? ccButton : bccButton).isHidden = true
        }
        changed()
        recipientsChanged()
    }

    @objc private func showCcRow() {
        grid.row(at: Row.cc).isHidden = false
        ccButton.isHidden = true
        window.makeFirstResponder(cc)
    }

    @objc private func showBccRow() {
        grid.row(at: Row.bcc).isHidden = false
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
    /// the From list: each account as "Name <address>", with its other addresses after it
    private func fillFrom() {
        guard let choices = pe_from_choices(core.handle) else { return }
        defer { pe_from_choices_free(choices) }
        for index in 0..<pe_from_choices_count(choices) {
            guard let choice = pe_from_choices_get(choices, index)?.pointee else { continue }
            // the same words can be two rows (an address and an account's): items are told apart by position
            from.addItem(withTitle: "")
            from.lastItem?.title = text(choice.label)
            fromChoices.append((choice.account, text(choice.address)))
        }
        selectFrom("")
    }

    /// the From list at the account's `address` ("" for its own)
    private func selectFrom(_ address: String) {
        if let index = fromChoices.firstIndex(where: { $0.account == account && $0.address == address }) {
            from.selectItem(at: index)
            fromAddress = address
        }
    }

    /// another account or address chosen in From: the message goes from it; another account's servers, Sent Items,
    /// Drafts and signature with it
    @objc private func chooseFrom() {
        let chosen = from.indexOfSelectedItem
        guard fromChoices.indices.contains(chosen) else { return }
        let choice = fromChoices[chosen]
        guard choice.account != account || choice.address != fromAddress else { return }
        fromAddress = choice.address
        if choice.account != account {
            account = choice.account
            // its signature in place of the other's
            editor.signature(taken(pe_signature_block(core.handle, account)) ?? "")
        }
        changed()
        refreshSecurity()
        showFromNote()
    }

    /// the note under From: what the folder list marks the account with, beside the core's words
    private func makeFromNote() -> NSView {
        fromNote.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return fromNote
    }

    /// the note under From as the chosen account's state says, hidden while it is connected
    private func showFromNote() {
        let status = core.accountStatus(account)
        fromNoteText = status.composeNote
        fromNote.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if !fromNoteText.isEmpty {
            fromNote.addArrangedSubview(warningNote(fromNoteText, id: "compose.fromNote", picture: AccountMark.picture(status.mark)))
        }
        if grid.numberOfRows > Row.fromNote {
            grid.row(at: Row.fromNote).isHidden = fromNoteText.isEmpty
        }
    }

    /// `account`'s sign-in or connection changed: the note under From of the windows writing from it
    static func accountStateChanged(_ account: Int64) {
        for compose in open where compose.account == account {
            compose.showFromNote()
        }
    }

    // ---- the editor ----

    private func makeEditor(_ draft: PeDraftInfo?) {
        // a saved draft opened again goes on with what was written; anything new starts with the account's signature
        let saved = draft.map { !text($0.message_id).isEmpty } ?? false
        var body = draft.map { text($0.body) } ?? ""
        if !saved, let signature = taken(pe_signature_block(core.handle, account)) {
            body += signature
        }
        lastHtml = body
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
        handlers.edited = { [weak self] in self?.textEdited() }
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
        status.toolTip = text.isEmpty ? nil : text
    }

    /// where the link under the mouse, or else the one the cursor is in, goes; the status as it was without either
    private func showLink(_ link: String) {
        status.stringValue = link.isEmpty ? statusText : "\(link)    (" + Text.macCommandClickToOpen.text + ")"
    }

    /// the message changed since it was sent to Drafts or opened: a "saved" status no longer holds
    private func changed() {
        if !dirty && !filling {
            setStatus("")
        }
        dirty = true
        changes += 1
        scheduleAutosave()
    }

    /// the timer of the automatic saving, started again at each change: it saves once typing stops, and every half a
    /// minute while it does not (the core's rule)
    private func scheduleAutosave() {
        guard !filling, !autosaveOff else { return }
        let since = unsavedSince ?? Date()
        unsavedSince = since
        let wait = pe_autosave_wait(UInt64(max(0, Date().timeIntervalSince(since)) * 1000))
        cancelAutosave()
        autosaveTimer = after(TimeInterval(wait) / 1000) { [weak self] in self?.autosaveDue() }
    }

    private func cancelAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = nil
    }

    private func autosaveDue() {
        autosaveTimer = nil
        if dirty && window.isVisible {
            request(.autosave)
        }
    }

    /// opened again after a crash (pe_recovered): closing asks about it, and without saving leaves its copy in Drafts,
    /// as whether the user had kept it is not known
    func restored() {
        kept = true
        autosaved = true
        setStatus(Text.uiComposeRestored.text)
    }

    func controlTextDidChange(_ notification: Notification) {
        if !filling {
            changed()
        }
        if notification.object as? NSTextField === subject {
            // the window named by its subject as it is typed, as one opened with a subject is
            window.title = subject.stringValue.isEmpty ? Text.uiNewMessageTitle.text : subject.stringValue
        }
        if let field = notification.object as? AddressField {
            field.typed(notification)
            // the locks of the recipients once typing stops
            recipientsTimer?.invalidate()
            recipientsTimer = after(0.4) { [weak self] in self?.recipientsChanged() }
        }
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
        if grid.numberOfRows > Row.attach {
            grid.row(at: Row.attach).isHidden = files.isEmpty
        }
        // a forwarded encrypted message's files can only go encrypted
        if !filling {
            refreshSecurity()
        }
    }

    @objc private func attach() {
        addFiles(openFilesPanel(title: Text.uiInsertAttachment.text))
    }

    /// a file taken off in the Attach row (Delete, or Remove in its menu); an address field left: its recipients' locks
    func controlTextDidEndEditing(_ notification: Notification) {
        if notification.object is AddressField {
            recipientsChanged()
            return
        }
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
        let item = NSMenuItem(title: Text.uiRemove.text, action: #selector(removeFile(_:)), keyEquivalent: "")
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
            requestedAt = changes
            editor.requestHtml()
        } else if action.weight > pending.weight {
            // the HTML asked for already serves the weightier action
            pending = action
        }
    }

    /// `changes` when the editor's HTML was asked for
    private var requestedAt = 0

    private func htmlArrived(_ html: String, quote state: EditorQuote, edited: String) {
        quoteState = state
        editedQuote = edited
        lastHtml = html
        let action = pending
        pending = .none
        switch action {
        case .send: send(html)
        case .save: save(html, close: false)
        case .saveAndClose: save(html, close: true)
        case .autosave: autosave(html)
        case .look, .none: break
        }
        // the quote unfolded, edited or deleted: whether it may still go in the clear
        if action != .send && window.isVisible {
            refreshSecurity()
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
            quote_plain: quotePlain, quote_text: folded && !quoteText.isEmpty ? strings.add(quoteText) : nil,
            from: strings.optional(fromAddress), sign: sign, encrypt: encrypt, quote_encrypted: quoteEncrypted)
    }

    /// sends with the HTML the editor gave, now or with the next Send/Recv
    private func send(_ html: String) {
        let strings = CStrings()
        var message = outgoing(html, strings)
        // signed or encrypted as it can not go: what is missing asked for first
        if sendBlocked(&message) {
            return
        }
        // it says a file is attached and none is: Go Back is the default
        if let word = taken(pe_forgotten_attachment(&message)),
           ask(Text.uiAttachmentForgotten.text(["word": word]), yes: Text.uiGoBack.text, no: Text.uiSendAnyway.text) {
            return
        }
        var reason: UnsafeMutablePointer<CChar>?
        guard pe_message_send(core.handle, account, &message, &reason) else {
            // a typo in an address or a file that is gone: the message stays open to fix it
            inform(taken(reason) ?? Text.uiNotSent.text, style: .warning)
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
            inform(taken(reason) ?? Text.uiNotSaved.text, style: .warning)
            // not closing after all: the app does not wait for it
            if close {
                AppDelegate.shared.quitAfterCompose = false
            }
            return
        }
        draftAccount = account
        messageId = taken(id) ?? ""
        kept = true
        autosaved = false
        savedClean()
        // the server's answer follows (draftSaved)
        setStatus(Text.macSavingToDrafts.text)
        if close {
            closeNow()
        }
    }

    /// saved in Drafts without being asked; quietly not when it can not be (no Drafts folder), the window says so
    private func autosave(_ html: String) {
        let strings = CStrings()
        var message = outgoing(html, strings)
        var id: UnsafeMutablePointer<CChar>?
        guard pe_draft_autosave(core.handle, account, &message, &id, nil) else {
            autosaveOff = true
            return
        }
        draftAccount = account
        messageId = taken(id) ?? ""
        autosaved = true
        savedClean()
        setStatus(Text.macSavingToDrafts.text)
    }

    /// the message as it was when its HTML was asked for is saved: clean unless it changed since
    private func savedClean() {
        cancelAutosave()
        unsavedSince = nil
        guard changes == requestedAt else {
            scheduleAutosave()
            return
        }
        dirty = false
        editor.clean()
    }

    @objc func sendClicked() { request(.send) }
    @objc private func saveClicked() { request(.save) }

    // ---- closing ----

    /// whether the window may close now: when nothing changed since it was sent or saved, or the user does not want
    /// it saved. Save saves it in Drafts and closes the window after.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard dirty || autosaved else { return true }
        switch askYesNoCancel(Text.uiSaveChangesAsk.text, yes: Text.uiTbSave.text, no: Text.macDontSave.text) {
        case .yes:
            request(.saveAndClose)
            return false
        case .no:
            discardAutosaved()
            return true
        case .cancel:
            return false
        }
    }

    /// closed without saving: the copy only the automatic saving made goes from Drafts
    private func discardAutosaved() {
        if autosaved && !kept && !messageId.isEmpty {
            _ = messageId.withCString { pe_draft_discard(core.handle, draftAccount, $0) }
        }
        autosaved = false
    }

    func windowWillClose(_ notification: Notification) {
        cancelAutosave()
        recipientsTimer?.invalidate()
        // nothing left to open again after a crash
        if !messageId.isEmpty {
            messageId.withCString { pe_compose_closed(core.handle, $0) }
        }
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
                compose.autosaved = false
                compose.closeNow()
                continue
            }
            // still open: saving before it closes (Save), or kept open (Cancel), which keeps the app too
            guard compose.pending == .saveAndClose else { return .kept }
            saving = true
        }
        return saving ? .saving : .closed
    }

    /// the UI test's crash: the window goes without closing, so its copy for a crash stays
    func abandon() {
        cancelAutosave()
        window.delegate = nil
        window.orderOut(nil)
        editor.close()
        ComposeWindow.open.removeAll { $0 === self }
    }

    /// opens again the messages that were being written when the app last ended without closing them
    static func openRecovered(core: Core) {
        guard let list = pe_recovered(core.handle) else { return }
        defer { pe_recovered_free(list) }
        for index in 0..<pe_recovered_count(list) {
            var account: Int64 = 0
            guard let draft = Draft(pe_recovered_get(list, index, &account)) else { continue }
            open(core: core, account: account, draft: draft).restored()
        }
    }

    /// the server's answer to a save: the window that saved it says so; false when no window has that draft
    static func draftSaved(messageId: String, problem: String) -> Bool {
        guard !messageId.isEmpty, let compose = open.first(where: { $0.messageId == messageId }) else { return false }
        compose.setStatus(problem.isEmpty ? Text.uiComposeSavedAt.text(["time": timeNow()])
                                          : Text.uiComposeNotSaved.text(["reason": problem]))
        return true
    }
}

// ---- signing and encrypting ----

extension ComposeWindow: RecipientKeysOwner {
    /// what the core says of signing and encrypting the message as it is now, shown: the toolbar's switches, the line
    /// under the fields, the Keys row and Recipients' Keys
    func refreshSecurity() {
        let strings = CStrings()
        var message = outgoing(lastHtml, strings)
        guard let state = ComposeSecurityState(pe_compose_security(core.handle, account, &message)) else { return }
        security = state
        showSecurity()
    }

    private func showSecurity() {
        showSwitches()
        let line = security.tone != PE_PROTECTION_TONE_NONE
        securityLine.show(tone: security.tone, encrypted: security.encrypt, text: security.text)
        securityLine.detailsButton.isHidden = !security.encrypt
        formatBarTop.isActive = !line
        formatBarUnderLine.isActive = line
        // the recipients' locks, while Encrypt is on
        keysRow.show(security.recipients)
        if grid.row(at: Row.keys).isHidden == security.showKeys {
            grid.row(at: Row.keys).isHidden = !security.showKeys
        }
        keysSheet?.refresh()
    }

    /// the toolbar's Sign and Encrypt as the core has them
    private func showSwitches() {
        signButton?.state = security.sign ? .on : .off
        // an encrypted message is always signed: Sign shows on and can not be clicked, its tip says why (on the item,
        // as a disabled button shows none)
        signButton?.isEnabled = security.signEnabled
        signButton?.superview?.toolTip = security.signTip
        signItem?.toolTip = security.signTip
        signButton?.setAccessibilityHelp(security.signTip)
        encryptButton?.state = security.encrypt ? .on : .off
        encryptButton?.superview?.toolTip = security.encryptTip
        encryptItem?.toolTip = security.encryptTip
        encryptButton?.setAccessibilityHelp(security.encryptTip)
    }

    /// the recipients changed: their locks, and with Encrypt on the keys of those that have none looked up
    func recipientsChanged() {
        recipientsTimer?.invalidate()
        recipientsTimer = nil
        if encrypt {
            findKeys()
        }
        refreshSecurity()
    }

    private func findKeys() {
        let strings = CStrings()
        var message = outgoing(lastHtml, strings)
        let request = pe_compose_find_keys(core.handle, account, &message)
        if request != 0 {
            lookups.insert(request)
        }
    }

    /// what was written changed (once typing pauses): while the core watches it, whether it still quotes encrypted mail
    private func textEdited() {
        if security.watchText {
            request(.look)
        }
    }

    /// keys were looked up (KeysFound) or changed: a lookup this window started is taken in and told in the status
    /// bar; another window's may have found a key of this one's recipients too
    static func onEvent(_ event: CoreEvent) {
        guard event.kind == PE_EVENT_KIND_KEYS_FOUND || event.kind == PE_EVENT_KIND_KEYS_CHANGED else { return }
        for compose in open {
            compose.keysFound(event.kind == PE_EVENT_KIND_KEYS_FOUND ? event.uid : 0)
        }
    }

    private func keysFound(_ request: UInt64) {
        if request != 0, lookups.remove(request) != nil, let said = taken(pe_pgp_find_result(core.handle, request)) {
            setStatus(said)
        }
        refreshSecurity()
    }

    /// a click on Sign or Encrypt (the toolbar, the menu, the keys): `on` what it is to become; the core may ask first
    func toggle(_ which: PeComposeSwitch, on: Bool, confirmed: Bool = false) {
        let strings = CStrings()
        var message = outgoing(lastHtml, strings)
        guard let question = took(pe_compose_toggle(core.handle, account, &message, which, on, confirmed)),
              asked(question) else { return }
        switch question.kind {
        case PE_COMPOSE_QUESTION_MAKE_KEY:
            // New Key for the account it goes from, then the switch again
            if KeyActions.makeKey(core: core, accounts: core.accounts().filter { $0.id == account }) != nil {
                toggle(which, on: on)
            }
        case PE_COMPOSE_QUESTION_SHOW_KEYS:
            KeysWindow.open(core: core)
            refreshSecurity()
        default:
            toggle(which, on: on, confirmed: true)
        }
    }

    /// a question of the core about the switches
    private struct Question {
        let kind: PeComposeQuestion
        let text: String
        let yes: String
        let no: String
    }

    /// what a click on a switch came to (`pe_compose_toggle`, `pe_compose_send_unencrypted`), taken in: the switches
    /// it keeps and the lookup it started; its question, nil without one (or on failure)
    private func took(_ result: UnsafeMutablePointer<PeComposeToggled>?) -> Question? {
        guard let result else {
            showSecurity()
            return nil
        }
        defer { pe_compose_toggled_free(result) }
        let toggled = result.pointee
        if toggled.lookup != 0 {
            lookups.insert(toggled.lookup)
        }
        if toggled.sign != sign || toggled.encrypt != encrypt {
            sign = toggled.sign
            encrypt = toggled.encrypt
            changed()
        }
        refreshSecurity()
        guard toggled.question != PE_COMPOSE_QUESTION_NONE else { return nil }
        let word = { (index: UInt32) in Text(rawValue: index)?.opens ?? "" }
        return Question(kind: toggled.question, text: text(toggled.text), yes: word(toggled.yes), no: word(toggled.no))
    }

    /// the core's question asked, true on Yes: the safe answer (Cancel, Keep It Encrypted) is the default, turning
    /// encryption off is marked as destructive
    private func asked(_ question: Question) -> Bool {
        let off = question.kind == PE_COMPOSE_QUESTION_TURN_OFF_ENCRYPT
        return ask(question.text, yes: question.yes, no: question.no, style: off ? .warning : .information, destructive: off,
                   safeDefault: true)
    }

    @objc func signClicked() {
        // the button changed its own state with the click: the core's answer sets it
        toggle(PE_COMPOSE_SWITCH_SIGN, on: !sign)
    }

    @objc func encryptClicked() {
        toggle(PE_COMPOSE_SWITCH_ENCRYPT, on: !encrypt)
    }

    /// File > Attach My Public Key: the key of the address it goes from, attached as a file
    func attachMyKey() {
        let strings = CStrings()
        var message = outgoing(lastHtml, strings)
        var error: UnsafeMutablePointer<CChar>?
        guard let path = taken(pe_compose_own_key_file(core.handle, account, &message, &error)) else {
            inform(taken(error) ?? Text.uiNotSent.text, style: .warning)
            return
        }
        addFiles([URL(fileURLWithPath: path)])
    }

    /// the commands of the menus about the compose window in front
    func perform(_ command: Command) {
        switch command {
        case .composeSign:
            if security.signEnabled { signClicked() }
        case .composeEncrypt: encryptClicked()
        case .attachMyKey: attachMyKey()
        default: break
        }
    }

    /// whether a command of the compose window can be chosen now, and whether it shows checked
    func validate(_ command: Command) -> (enabled: Bool, on: Bool) {
        switch command {
        case .composeSign: (security.signEnabled, security.sign)
        case .composeEncrypt: (true, security.encrypt)
        case .attachMyKey: (security.hasOwnKey, false)
        default: (false, false)
        }
    }

    /// Send of a message that can not go as it is signed or encrypted: what is missing asked for, and true
    private func sendBlocked(_ message: inout PeOutgoing) -> Bool {
        guard let state = ComposeSecurityState(pe_compose_security(core.handle, account, &message)) else { return false }
        security = state
        showSecurity()
        switch state.block {
        case PE_COMPOSE_BLOCK_MISSING_KEYS:
            openRecipientKeys()
        case PE_COMPOSE_BLOCK_NO_OWN_KEY:
            // the question of the switch that needs the key: Make a Key, or Encryption Keys
            toggle(encrypt ? PE_COMPOSE_SWITCH_ENCRYPT : PE_COMPOSE_SWITCH_SIGN, on: true)
        case PE_COMPOSE_BLOCK_ENCRYPTED_QUOTE:
            inform(state.blockText, style: .warning)
        default:
            return false
        }
        return true
    }

    /// Recipients' Keys, a sheet on the window: Send there sends encrypted, Send Without Encryption without
    /// encrypting (Sign as the user had it)
    func openRecipientKeys() {
        guard keysSheet == nil else { return }
        let sheet = RecipientKeysSheet(owner: self)
        keysSheet = sheet
        let answer = sheet.run(on: window)
        keysSheet = nil
        switch answer {
        case .send:
            request(.send)
        case .sendUnencrypted:
            sendUnencrypted()
        case .cancel:
            break
        }
    }

    /// Send Without Encryption: Encrypt off as the core has it (asking first while the message carries something
    /// encrypted), then Send
    private func sendUnencrypted() {
        let strings = CStrings()
        var message = outgoing(lastHtml, strings)
        if let question = took(pe_compose_send_unencrypted(core.handle, account, &message)) {
            guard asked(question) else { return }
            toggle(PE_COMPOSE_SWITCH_ENCRYPT, on: false, confirmed: true)
        }
        if !encrypt {
            request(.send)
        }
    }

    func findKey(_ address: String) {
        let request = address.withCString { pe_compose_find_key(core.handle, $0) }
        if request != 0 {
            lookups.insert(request)
        }
        refreshSecurity()
    }

    /// Remove from Message: the address out of To, Cc or Bcc
    func removeRecipient(_ address: String) {
        let strings = CStrings()
        var message = outgoing(lastHtml, strings)
        var toList: UnsafeMutablePointer<CChar>?
        var ccList: UnsafeMutablePointer<CChar>?
        var bccList: UnsafeMutablePointer<CChar>?
        guard address.withCString({ pe_compose_without_recipient(&message, $0, &toList, &ccList, &bccList) }) else { return }
        for (field, list) in zip([to, cc, bcc], [toList, ccList, bccList]) {
            field.stringValue = taken(list) ?? field.stringValue
        }
        changed()
        refreshSecurity()
    }

    func decideKey(_ address: String, useNew: Bool) {
        _ = address.withCString { pe_pgp_decide(core.handle, $0, useNew) }
        refreshSecurity()
    }
}

extension ComposeWindow: NSToolbarDelegate {
    private static var items: [(String, String, String, Selector)] {
        [
            ("send", Text.uiTbSend.text, "send", #selector(sendClicked)), ("save", Text.uiTbSave.text, "save", #selector(saveClicked)),
            ("attach", Text.uiTbAttach.text, "attach", #selector(attach)),
            ("sign", Text.uiTbSign.text, "ribbon", #selector(signClicked)),
            ("encrypt", Text.uiTbEncrypt.text, "lock_closed", #selector(encryptClicked)),
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        // Sign and Encrypt apart at the end, as Apple Mail keeps its lock and seal away from Send
        [NSToolbarItem.Identifier("send"), .space, NSToolbarItem.Identifier("save"), .space, NSToolbarItem.Identifier("attach"),
         .flexibleSpace, NSToolbarItem.Identifier("sign"), NSToolbarItem.Identifier("encrypt")]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let (id, label, icon, action) = ComposeWindow.items.first(where: { $0.0 == identifier.rawValue }) else { return nil }
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.toolTip = label
        guard id == "sign" || id == "encrypt" else {
            item.image = Icons.toolbar(icon)
            item.target = self
            item.action = action
            item.isBordered = true
            return item
        }
        // a switch that stays pressed while it is on, in a holder that shows its tip while it can not be clicked
        let button = NSButton(image: Icons.toolbar(icon) ?? NSImage(), target: self, action: action)
        button.title = ""
        button.setButtonType(.pushOnPushOff)
        button.bezelStyle = .toolbar
        button.setAccessibilityLabel(label)
        button.setAccessibilityIdentifier("compose.\(id)")
        let holder = NSView()
        button.translatesAutoresizingMaskIntoConstraints = false
        holder.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: holder.leadingAnchor), button.trailingAnchor.constraint(equalTo: holder.trailingAnchor),
            button.topAnchor.constraint(equalTo: holder.topAnchor), button.bottomAnchor.constraint(equalTo: holder.bottomAnchor),
        ])
        item.view = holder
        if id == "sign" {
            signButton = button
            signItem = item
        } else {
            encryptButton = button
            encryptItem = item
        }
        showSwitches()
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
        // not while an input method composes: completing would replace its unconfirmed text
        guard !completing, let editor = currentEditor() as? NSTextView, !editor.hasMarkedText(),
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

    /// what the list shows for a group of the address book, and what choosing it puts in the field: its members
    private var groupLabels: [String: String] = [:]

    /// whether the first of the people listed last may be chosen as the user types: only one whose text begins with
    /// what was typed (the core's `inline`), filled in after it; otherwise the list only offers, and what is typed stays
    private(set) var firstFillsIn = false

    /// the people (and groups) for `typed`, as the core finds them; a group by its name, with the group symbol
    @MainActor
    func people(_ typed: String) -> [String] {
        // a whole address typed with its brackets is not looked up again
        guard let core, !typed.isEmpty, !typed.contains("<") else { return [] }
        firstFillsIn = false
        guard let list = typed.withCString({ pe_contacts(core.handle, $0, 8) }) else { return [] }
        defer { pe_contact_list_free(list) }
        groupLabels = [:]
        // a person whose text begins with what was typed; a group whose name does (it goes in as its members)
        if let first = pe_contact_list_get(list, 0)?.pointee {
            firstFillsIn = first.fills_in || (first.group && first.completes)
        }
        return (0..<pe_contact_list_count(list)).compactMap { pe_contact_list_get(list, $0)?.pointee }.map { contact in
            guard contact.group else { return text(contact.label) }
            let shown = "\u{1F465} " + text(contact.name)
            groupLabels[shown] = text(contact.label)
            return shown
        }
    }

    /// what a choice of the list puts in the field: a group's members, else what it shows
    func inserted(_ word: String) -> String {
        groupLabels[word] ?? word
    }
}

extension ComposeWindow {
    func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange range: NSRange,
                 indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        guard let field = control as? AddressField else { return [] }
        let people = field.people((textView.string as NSString).substring(with: range))
        // the best one chosen (and filled in as the user types) only when it begins with what was typed; otherwise
        // nothing is: what is typed stays, and Return or Tab keep it (a new address that resembles someone's)
        index.pointee = field.firstFillsIn ? 0 : -1
        return people
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
        // a group of the address book goes in as its members
        let word = ((delegate as AnyObject?) as? AddressField)?.inserted(word) ?? word
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
        // wide enough for the whole format bar
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 360), styleMask: [.titled, .resizable], backing: .buffered,
                          defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiSignatureOf.text(["account": name])
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
        let hint = NSTextField(labelWithString: Text.uiSignatureHint.text)
        hint.textColor = .secondaryLabelColor
        let cancel = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        let okButton = NSButton(title: Text.uiOk.text, target: self, action: #selector(ok))
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
            // the window is never made narrower than the bar
            formatBar.view.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -10),
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
            inform(Text.uiSignatureNotSaved.text, title: Text.uiSignature.text, style: .error)
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
