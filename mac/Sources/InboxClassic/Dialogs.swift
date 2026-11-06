// The small windows the others are built from: messages and questions, a form of labeled fields, a text to read, a
// window that waits for the core and can cancel it, and the file panels. Each runs modally until it is answered, as
// the Windows app's dialogs do, so the code that asks reads top to bottom.
import AppKit
import UniformTypeIdentifiers

let appName = "Inbox Classic"

// ---- messages and questions ----

enum AlertStyle {
    case information, warning, error
}

/// A message with OK
@MainActor
func inform(_ text: String, title: String = appName, style: AlertStyle = .information, in window: NSWindow? = nil) {
    let alert = makeAlert(text, title: title, style: style)
    alert.addButton(withTitle: "OK")
    run(alert)
}

/// A question; true for the first button. `destructive` makes the second one the default, as for deleting
@MainActor
func ask(_ text: String, title: String = appName, yes: String = "Yes", no: String = "No", style: AlertStyle = .warning,
         destructive: Bool = false) -> Bool {
    let alert = makeAlert(text, title: title, style: style)
    let first = alert.addButton(withTitle: yes)
    let second = alert.addButton(withTitle: no)
    if destructive {
        first.hasDestructiveAction = true
        first.keyEquivalent = ""
        second.keyEquivalent = "\r"
    }
    return run(alert) == .alertFirstButtonReturn
}

/// Yes, No or Cancel
enum Answer {
    case yes, no, cancel
}

@MainActor
func askYesNoCancel(_ text: String, title: String = appName, yes: String = "Yes", no: String = "No") -> Answer {
    let alert = makeAlert(text, title: title, style: .warning)
    alert.addButton(withTitle: yes)
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: no)
    switch run(alert) {
    case .alertFirstButtonReturn: return .yes
    case .alertThirdButtonReturn: return .no
    default: return .cancel
    }
}

@MainActor
private func makeAlert(_ text: String, title: String, style: AlertStyle) -> NSAlert {
    let alert = NSAlert()
    // the first line as the title, the rest under it, as Mac alerts have it
    let parts = text.components(separatedBy: "\n\n")
    if parts.count > 1 {
        alert.messageText = parts[0]
        alert.informativeText = parts.dropFirst().joined(separator: "\n\n")
    } else {
        alert.messageText = text
    }
    alert.alertStyle = style == .information ? .informational : style == .warning ? .warning : .critical
    alert.window.title = title
    alert.window.identifier = NSUserInterfaceItemIdentifier("alert")
    return alert
}

@MainActor
@discardableResult
private func run(_ alert: NSAlert) -> NSApplication.ModalResponse {
    Modal.opened(alert.window)
    defer { Modal.closed(alert.window) }
    return alert.runModal()
}

/// The modal windows open now, the last in front: what the UI test answers
@MainActor
enum Modal {
    static private(set) var windows: [NSWindow] = []

    static func opened(_ window: NSWindow) {
        windows.append(window)
    }

    static func closed(_ window: NSWindow) {
        windows.removeAll { $0 === window }
    }
}

// ---- a form of labeled fields ----

struct FormField {
    enum Kind {
        case text, password, number, choice([String])
    }

    var label: String
    var value: String = ""
    var kind: Kind = .text
    /// for a choice: the position of the one chosen
    var chosen: Int = 0
}

/// A modal form: a label and an input for each field, OK and Cancel; the fields with their values when OK was
/// pressed, nil when cancelled. `validate` gets the values and returns an error to show, nil to accept them.
@MainActor
func formDialog(title: String, intro: String, fields: [FormField], ok: String = "OK", focus: Int = 0,
                validate: (([FormField]) -> String?)? = nil) -> [FormField]? {
    let form = FormWindow(title: title, intro: intro, fields: fields, ok: ok, focus: focus, validate: validate)
    return form.run()
}

@MainActor
final class FormWindow: NSObject, NSWindowDelegate {
    let window: NSWindow
    private var fields: [FormField]
    private var inputs: [NSView] = []
    private let validate: (([FormField]) -> String?)?
    private var accepted = false

    init(title: String, intro: String, fields: [FormField], ok: String, focus: Int, validate: (([FormField]) -> String?)?) {
        self.fields = fields
        self.validate = validate
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 200), styleMask: [.titled], backing: .buffered,
                          defer: true)
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier("form")
        super.init()
        window.delegate = self

        let introLabel = wrappingLabel(intro)
        let grid = NSGridView()
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        for (index, field) in fields.enumerated() {
            let input = makeInput(field, index: index)
            inputs.append(input)
            let label = NSTextField(labelWithString: field.label)
            label.alignment = .right
            grid.addRow(with: [label, input])
        }
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        if grid.numberOfColumns > 1 {
            grid.column(at: 1).width = 260
        }

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.setAccessibilityIdentifier("form.cancel")
        let okButton = NSButton(title: ok, target: self, action: #selector(accept))
        okButton.keyEquivalent = "\r"
        okButton.setAccessibilityIdentifier("form.ok")
        let buttons = buttonRow([cancelButton, okButton])

        let stack = NSStackView(views: [introLabel, grid, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(20, after: grid)
        window.contentView = stack
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        introLabel.widthAnchor.constraint(equalToConstant: 420).isActive = true
        window.initialFirstResponder = inputs.indices.contains(focus) ? inputs[focus] : inputs.first
    }

    private func makeInput(_ field: FormField, index: Int) -> NSView {
        let input: NSView
        switch field.kind {
        case .choice(let choices):
            let popup = NSPopUpButton(frame: .zero, pullsDown: false)
            popup.addItems(withTitles: choices)
            popup.selectItem(at: choices.firstIndex(of: field.value) ?? field.chosen)
            input = popup
        case .password:
            let secure = NSSecureTextField(string: field.value)
            input = secure
        case .text, .number:
            let plain = NSTextField(string: field.value)
            plain.lineBreakMode = .byTruncatingTail
            plain.cell?.isScrollable = true
            input = plain
        }
        input.setAccessibilityIdentifier("form.field.\(index)")
        input.setAccessibilityLabel(field.label)
        return input
    }

    /// what the inputs hold now
    private func read() -> [FormField] {
        var values = fields
        for (index, input) in inputs.enumerated() {
            if let popup = input as? NSPopUpButton {
                values[index].chosen = popup.indexOfSelectedItem
                values[index].value = popup.titleOfSelectedItem ?? ""
            } else if let field = input as? NSTextField {
                values[index].value = field.stringValue.trimmingCharacters(in: .whitespaces)
            }
        }
        return values
    }

    @objc func accept() {
        let values = read()
        if let error = validate?(values) {
            inform(error, title: window.title, style: .warning)
            return
        }
        fields = values
        accepted = true
        NSApp.stopModal()
    }

    @objc func cancel() {
        NSApp.stopModal()
    }

    func run() -> [FormField]? {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        // what was typed in a password field does not stay in the window
        for input in inputs {
            (input as? NSSecureTextField)?.stringValue = ""
        }
        return accepted ? fields : nil
    }
}

/// The name of a folder to make or rename, asked for; nil when cancelled
@MainActor
func askFolderName(title: String, intro: String, name: String) -> String? {
    formDialog(title: title, intro: intro, fields: [FormField(label: "Folder name:", value: name)])?[0].value
}

/// Why the core refused, or `fallback` when it did not say
@MainActor
func refused(_ reason: UnsafeMutablePointer<CChar>?, _ fallback: String) {
    inform(taken(reason) ?? fallback, style: .warning)
}

/// The buttons of a window in a row at its right, the default last, as Mac windows have them; as wide as its window
/// once given that width
@MainActor
func buttonRow(_ buttons: [NSButton]) -> NSStackView {
    let spacer = NSView()
    spacer.setContentHuggingPriority(.init(1), for: .horizontal)
    let row = NSStackView(views: [spacer] + buttons)
    row.spacing = 12
    for button in buttons {
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    }
    return row
}

/// A label that wraps to the width it is given
@MainActor
func wrappingLabel(_ text: String) -> NSTextField {
    let label = NSTextField(wrappingLabelWithString: text)
    label.isSelectable = false
    return label
}

// ---- a text to read ----

/// A window with `text` to read and copy, and OK (Message Properties)
@MainActor
func textDialog(title: String, intro: String?, text: String, ok: String = "OK", id: String = "text",
                size: NSSize = NSSize(width: 640, height: 440), action: ButtonAction? = nil) {
    let window = TextDialogWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled, .resizable],
                                  backing: .buffered, defer: true)
    window.title = title
    window.identifier = NSUserInterfaceItemIdentifier(id)
    let scroll = NSTextView.scrollableTextView()
    let view = scroll.documentView as! NSTextView
    view.isEditable = false
    view.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    view.string = text
    view.setAccessibilityIdentifier("text.body")
    let ok = NSButton(title: ok, target: NSApp, action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
    ok.keyEquivalent = "\r"
    // a button that does not close the window on the left, the one that does on the right
    let buttons = NSStackView(views: (action.map { [$0.button] } ?? []) + [NSView(), ok])
    buttons.orientation = .horizontal
    let stack = NSStackView(views: (intro.map { [NSTextField(labelWithString: $0)] } ?? []) + [scroll, buttons])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    scroll.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
    scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
    buttons.widthAnchor.constraint(equalTo: scroll.widthAnchor).isActive = true
    window.contentView = stack
    window.center()
    Modal.opened(window)
    NSApp.runModal(for: window)
    Modal.closed(window)
    window.orderOut(nil)
}

/// The window of [`textDialog`]: Esc closes it, as Close does
final class TextDialogWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        NSApp.stopModal()
    }
}

/// A button that runs a closure, for a dialog's own action (Save As in View Source)
@MainActor
final class ButtonAction: NSObject {
    let button: NSButton
    private let run: () -> Void

    init(_ title: String, id: String, run: @escaping () -> Void) {
        self.run = run
        button = NSButton(title: title, target: nil, action: nil)
        super.init()
        button.target = self
        button.action = #selector(press)
        button.setAccessibilityIdentifier(id)
    }

    @objc private func press() {
        run()
    }
}

// ---- waiting for the core ----

/// What a window that waits for a request of the core waits for; the main window hands it the request's event
@MainActor
enum Waiting {
    private static var request: UInt64 = 0
    private static var done = false

    /// the event of `request` came
    static func requestDone(_ request: UInt64) {
        if request != 0 && request == Self.request {
            done = true
            NSApp.stopModal()
        }
    }

    /// waits for the event of `request` in a small window that says `text` and can cancel it; false when cancelled
    static func wait(for request: UInt64, text: String, title: String, cancel: @escaping (UInt64) -> Void) -> Bool {
        guard request != 0 else { return false }
        Self.request = request
        done = false
        let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 120), styleMask: [.titled],
                             backing: .buffered, defer: true)
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier("wait")
        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.startAnimation(nil)
        let label = wrappingLabel(text)
        label.setAccessibilityIdentifier("wait.text")
        let cancelButton = NSButton(title: "Cancel", target: NSApp, action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
        cancelButton.keyEquivalent = "\u{1b}"
        let row = NSStackView(views: [spinner, label])
        row.alignment = .top
        let stack = NSStackView(views: [row, cancelButton])
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
        label.widthAnchor.constraint(equalToConstant: 300).isActive = true
        window.contentView = stack
        window.center()
        // the event may have come before the window is shown
        if !done {
            Modal.opened(window)
            NSApp.runModal(for: window)
            Modal.closed(window)
        }
        window.orderOut(nil)
        Self.request = 0
        if !done {
            cancel(request)
        }
        return done
    }
}

// ---- files ----

/// What the UI test answers in place of the system's file panels, which run in a process of their own
@MainActor
enum TestHooks {
    /// a test is driving the app: nothing it does is remembered for the user (window places, preferences)
    static var testing = false
    static var save: ((String) -> URL?)?
    static var open: ((String) -> [URL])?
    static var folder: (() -> URL?)?
}

/// Where to save a file, starting from the safe name the core made, in Downloads; nil when cancelled
@MainActor
func saveFilePanel(name: String, title: String = "Save Attachment As", types: [UTType] = []) -> URL? {
    if let answer = TestHooks.save { return answer(name) }
    let panel = NSSavePanel()
    panel.title = title
    panel.nameFieldStringValue = name
    panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    if !types.isEmpty {
        panel.allowedContentTypes = types
        panel.allowsOtherFileTypes = true
    }
    panel.identifier = NSUserInterfaceItemIdentifier("save")
    Modal.opened(panel)
    defer { Modal.closed(panel) }
    return panel.runModal() == .OK ? panel.url : nil
}

/// The files chosen, none when cancelled
@MainActor
func openFilesPanel(title: String, types: [UTType] = [], multiple: Bool = true) -> [URL] {
    if let answer = TestHooks.open { return answer(title) }
    let panel = NSOpenPanel()
    panel.title = title
    panel.allowsMultipleSelection = multiple
    panel.canChooseDirectories = false
    if !types.isEmpty {
        panel.allowedContentTypes = types
    }
    panel.identifier = NSUserInterfaceItemIdentifier("open")
    Modal.opened(panel)
    defer { Modal.closed(panel) }
    return panel.runModal() == .OK ? panel.urls : []
}

/// A folder chosen, nil when cancelled
@MainActor
func folderPanel(title: String) -> URL? {
    if let answer = TestHooks.folder { return answer() }
    let panel = NSOpenPanel()
    panel.title = title
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.prompt = "Choose"
    panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    panel.identifier = NSUserInterfaceItemIdentifier("folder")
    Modal.opened(panel)
    defer { Modal.closed(panel) }
    return panel.runModal() == .OK ? panel.url : nil
}

/// Writes a saved file and marks it as from the internet, so Gatekeeper and Quick Look treat it as such
func writeDownloaded(_ data: Data, to url: URL) -> Bool {
    do {
        try data.write(to: url)
        markFromInternet(url)
        return true
    } catch {
        return false
    }
}

/// The quarantine mark macOS gives downloads, for a file saved from a message
func markFromInternet(_ url: URL) {
    var values = URLResourceValues()
    values.quarantineProperties = [kLSQuarantineTypeKey as String: kLSQuarantineTypeOtherDownload,
                                   kLSQuarantineAgentNameKey as String: appName]
    var target = url
    try? target.setResourceValues(values)
}
