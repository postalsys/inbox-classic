// The compose window's editor: a WKWebView with the page of pe_editor_document, whose own script (allowed by a nonce,
// nothing else can run) makes the message editable. The page talks back with plain strings through the "host"
// message handler (see core/crates/pe-html/src/editor.js), the window drives it with the page's pe.* functions. The
// rest is locked down as the reading pane is: no network, no navigation, no window, nothing kept on disk.
import AppKit
import CInboxClassic
import WebKit

/// Where the quoted message is when the page gives its HTML: still folded (the draft's goes with the message),
/// unfolded and maybe edited (apart from what was written), or unfolded and deleted
enum EditorQuote {
    case folded, edited, removed
}

@MainActor
final class Editor: NSObject, WKScriptMessageHandler {
    struct Handlers {
        var html: (_ html: String, _ quote: EditorQuote, _ edited: String) -> Void = { _, _, _ in }
        /// one 0 or 1 per format: bold, italic, underline, numbers, bullets, left, center, right
        var state: (String) -> Void = { _ in }
        var dirty: () -> Void = {}
        /// Command-Return
        var send: () -> Void = {}
        /// Command-S
        var save: () -> Void = {}
        /// files dropped on the text, the cursor now where they were dropped
        var dropped: ([URL]) -> Void = { _ in }
        /// the link under the mouse, or else the one the cursor is in; empty for none
        var link: (String) -> Void = { _ in }
        /// Command-K, or Edit Link in the menu of a link
        var editLink: () -> Void = {}
    }

    let view: EditorView
    private let server = DocumentServer()
    private let navigation = StayOnPage()
    private var handlers = Handlers()
    private(set) var caretLink = ""
    private var hoverLink = ""

    init(document: String, handlers: Handlers) {
        let configuration = lockedConfiguration(server: server, scripts: true)
        view = EditorView(frame: .zero, configuration: configuration)
        self.handlers = handlers
        super.init()
        configuration.userContentController.add(WeakHandler(self), name: "host")
        view.navigationDelegate = navigation
        view.uiDelegate = navigation
        view.isInspectable = false
        view.allowsBackForwardNavigationGestures = false
        view.setAccessibilityIdentifier("editor")
        view.editor = self
        ContentRules.whenReady { [weak self] in
            guard let self else { return }
            view.load(URLRequest(url: server.serve(document, host: "compose", path: "page")))
        }
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        if body.hasPrefix("html:") {
            handlers.html(String(body.dropFirst(5)), .folded, "")
        } else if body.hasPrefix("split:") {
            // what was written, the separator, the quote: the first separator, as the quote may hold one
            let rest = body.dropFirst(6)
            if let separator = rest.firstIndex(of: "\u{1f}") {
                handlers.html(String(rest[..<separator]), .edited, String(rest[rest.index(after: separator)...]))
            } else {
                handlers.html(String(rest), .removed, "")
            }
        } else if body.hasPrefix("full:") {
            handlers.html(String(body.dropFirst(5)), .removed, "")
        } else if body.hasPrefix("state:") {
            handlers.state(String(body.dropFirst(6)))
        } else if body == "dirty" {
            handlers.dirty()
        } else if body == "drop" {
            handlers.dropped(view.takeDropped())
        } else if body.hasPrefix("caret:") || body.hasPrefix("hover:") {
            let link = String(body.dropFirst(6))
            if body.hasPrefix("caret:") { caretLink = link } else { hoverLink = link }
            handlers.link(hoverLink.isEmpty ? caretLink : hoverLink)
        } else if body.hasPrefix("open:") {
            openExternally(URL(string: String(body.dropFirst(5))))
        }
    }

    /// a formatting command of the page (bold, fontName, foreColor, insertImage...)
    func exec(_ command: String, _ value: String = "") {
        script("pe.exec(\(jsString(command)),\(jsString(value)))")
    }

    func link(_ url: String) {
        script("pe.link(\(jsString(url)))")
    }

    /// the signature block of another account in place of the one in the text
    func signature(_ block: String) {
        script("pe.signature(\(jsString(block)))")
    }

    /// asks the page for the body; it comes to Handlers.html
    func requestHtml() {
        script("pe.send()")
    }

    /// the body was saved: the next change is reported as dirty again
    func clean() {
        script("pe.clean()")
    }

    func focus() {
        view.window?.makeFirstResponder(view)
        script("window.pe && pe.focus()")
    }

    func editLink() { handlers.editLink() }
    func send() { handlers.send() }
    func save() { handlers.save() }

    private func script(_ code: String) {
        view.evaluateJavaScript(code, completionHandler: nil)
    }

    /// the page and its handler go, the handler holds the editor no longer
    func close() {
        view.configuration.userContentController.removeScriptMessageHandler(forName: "host")
        view.editor = nil
    }
}

/// `value` as a JavaScript string literal: everything but plain letters, digits and spaces escaped, so no value can
/// end the string
func jsString(_ value: String) -> String {
    var out = "'"
    for unit in value.utf16 {
        let c = Character(UnicodeScalar(unit) ?? " ")
        if unit < 128, c.isLetter || c.isNumber || c == " " {
            out.append(c)
        } else {
            out += String(format: "\\u%04x", unit)
        }
    }
    return out + "'"
}

/// The handler WebKit keeps, which does not keep the editor alive
private final class WeakHandler: NSObject, WKScriptMessageHandler {
    weak var target: Editor?
    init(_ target: Editor) { self.target = target }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated { target?.userContentController(controller, didReceive: message) }
    }
}

/// The editor's web view: its keys, its context menu without what does nothing here, and the paths of the files
/// dropped on it (the page gets their File objects but no paths; it says "drop", and the window takes these)
final class EditorView: WKWebView {
    weak var editor: Editor?
    private var dropped: [URL] = []

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dropped = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
            as? [URL] ?? []
        return super.performDragOperation(sender)
    }

    func takeDropped() -> [URL] {
        defer { dropped = [] }
        return dropped
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == .command, let editor {
            switch event.charactersIgnoringModifiers {
            case "\r":
                editor.send()
                return true
            case "s":
                editor.save()
                return true
            case "k":
                editor.editLink()
                return true
            // reloading the page would lose what was written
            case "r":
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        // what opens windows, saves, downloads or reloads does nothing in the editor
        let useless = ["Reload", "OpenLink", "OpenLinkInNewWindow", "DownloadLinkedFile", "OpenImageInNewWindow",
                       "DownloadImage", "OpenFrameInNewWindow", "Inspect", "Back", "Forward", "Share"]
        for item in menu.items.reversed() {
            let name = item.identifier?.rawValue ?? ""
            if useless.contains(where: { name.contains($0) }) {
                menu.removeItem(item)
            }
        }
        guard let editor, !editor.caretLink.isEmpty || menu.items.contains(where: { ($0.identifier?.rawValue ?? "").contains("CopyLink") })
        else {
            super.willOpenMenu(menu, with: event)
            return
        }
        let link = editor.caretLink
        let items = [
            NSMenuItem(title: Text.macOpenLink.text, action: #selector(openLink), keyEquivalent: ""),
            NSMenuItem(title: Text.macEditLink.text, action: #selector(editLink), keyEquivalent: ""),
            NSMenuItem(title: Text.macRemoveLink.text, action: #selector(removeLink), keyEquivalent: ""),
            NSMenuItem.separator(),
        ]
        for (index, item) in items.enumerated() {
            item.target = self
            item.representedObject = link
            menu.insertItem(item, at: index)
        }
        super.willOpenMenu(menu, with: event)
    }

    @objc private func openLink(_ item: NSMenuItem) {
        openExternally(URL(string: item.representedObject as? String ?? ""))
    }

    @objc private func editLink() {
        editor?.editLink()
    }

    @objc private func removeLink() {
        editor?.link("")
    }
}
