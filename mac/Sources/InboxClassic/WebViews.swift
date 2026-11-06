// The WKWebViews: the reading pane, the help and the print view show the core's documents with scripts off; the
// compose window's editor runs the page's own script only (allowed by a nonce in its CSP). The documents come from
// memory through the app's own scheme (inboxclassic:), as WebKit can not answer https requests itself, and every
// other load is blocked by the core's content rules (pe_webkit_content_rules): the second wall behind the documents'
// CSP, as WebView2's request filter is on Windows. Nothing is kept on disk, nothing navigates, no window opens, and
// links open in the browser.
import AppKit
import CInboxClassic
import WebKit

/// The scheme the documents are served from (pe_html::DOCUMENT_SCHEME)
let documentScheme = "inboxclassic"

/// Serves the documents of a web view from memory, by the path of their address
final class DocumentServer: NSObject, WKURLSchemeHandler {
    private var documents: [String: Data] = [:]

    /// `html` at inboxclassic://<host>/<path>; its address
    func serve(_ html: String, host: String, path: String) -> URL {
        documents[host + "/" + path] = Data(html.utf8)
        return URL(string: "\(documentScheme)://\(host)/\(path)")!
    }

    /// the documents served before, given up
    func clear() {
        documents.removeAll()
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, let host = url.host,
              let data = documents[host + "/" + url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))]
        else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "text/html; charset=utf-8"])!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

/// The core's content rules, compiled once: everything blocked, or the pictures of a message allowed too
@MainActor
enum ContentRules {
    private static var blocked: WKContentRuleList?
    private static var pictures: WKContentRuleList?
    private static var waiting: [() -> Void] = []
    private static var compiling = false

    /// runs `ready` once both lists are compiled; no document is shown before
    static func whenReady(_ ready: @escaping () -> Void) {
        if blocked != nil && pictures != nil {
            ready()
            return
        }
        waiting.append(ready)
        guard !compiling else { return }
        compiling = true
        let store = WKContentRuleListStore.default()!
        let rules = { (allow: Bool) in taken(pe_webkit_content_rules(allow)) ?? "" }
        store.compileContentRuleList(forIdentifier: "inboxclassic-blocked", encodedContentRuleList: rules(false)) { list, error in
            blocked = list
            if list == nil { fatalError("the content rules did not compile: \(String(describing: error))") }
            store.compileContentRuleList(forIdentifier: "inboxclassic-pictures", encodedContentRuleList: rules(true)) { list, error in
                pictures = list
                if list == nil { fatalError("the content rules did not compile: \(String(describing: error))") }
                waiting.forEach { $0() }
                waiting.removeAll()
            }
        }
    }

    /// the rules of a web view now: with the message's pictures from the internet or without
    static func apply(to controller: WKUserContentController, pictures allowed: Bool) {
        controller.removeAllContentRuleLists()
        if let list = allowed ? pictures : blocked {
            controller.add(list)
        }
    }
}

/// Opens a link of a message or of the help in the default browser (or mail program): http, https and mailto only
func openExternally(_ url: URL?) {
    guard let url, let scheme = url.scheme?.lowercased(), ["http", "https", "mailto"].contains(scheme) else { return }
    NSWorkspace.shared.open(url)
}

/// What every web view of the app has: no data kept, no dev tools, the documents from memory, the rules applied
@MainActor
func lockedConfiguration(server: DocumentServer, scripts: Bool) -> WKWebViewConfiguration {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = scripts
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
    configuration.preferences.isFraudulentWebsiteWarningEnabled = false
    configuration.preferences.isElementFullscreenEnabled = false
    configuration.mediaTypesRequiringUserActionForPlayback = .all
    configuration.allowsAirPlayForMediaPlayback = false
    configuration.setURLSchemeHandler(server, forURLScheme: documentScheme)
    ContentRules.apply(to: configuration.userContentController, pictures: false)
    return configuration
}

/// Lets a web view show only its own documents: a link the user clicked opens in the browser instead, anything else
/// that would navigate (a refresh, a form, a script) goes nowhere, and no window opens
final class StayOnPage: NSObject, WKNavigationDelegate, WKUIDelegate {
    var loaded: (() -> Void)?

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let scheme = action.request.url?.scheme?.lowercased() ?? ""
        // the document itself, and about:blank or about:srcdoc of its frames
        if (scheme == documentScheme && action.navigationType == .other) || scheme == "about" {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
        if action.navigationType == .linkActivated && scheme != documentScheme {
            openExternally(action.request.url)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // target=_blank: in the browser, the link clicked only
        if action.navigationType == .linkActivated {
            openExternally(action.request.url)
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded?()
    }
}

// ---- the reading pane ----

/// The message bodies: the sanitized documents of the core (pe_html_render), shown as they are, scripts off
@MainActor
final class Preview: NSObject {
    let view: WKWebView
    private let server = DocumentServer()
    private let navigation = StayOnPage()
    private var shown = 0
    private var pending: (String, Bool)?
    private var ready = false

    override init() {
        view = WKWebView(frame: .zero, configuration: lockedConfiguration(server: server, scripts: false))
        super.init()
        view.navigationDelegate = navigation
        view.uiDelegate = navigation
        view.allowsBackForwardNavigationGestures = false
        view.allowsMagnification = true
        view.isInspectable = false
        view.setAccessibilityIdentifier("preview")
        ContentRules.whenReady { [weak self] in
            guard let self else { return }
            ready = true
            if let (document, pictures) = pending {
                show(document, pictures: pictures)
            } else {
                clear()
            }
        }
    }

    /// a document of the core; with `pictures` its pictures from the internet are let through
    func show(_ document: String, pictures: Bool = false) {
        guard ready else {
            pending = (document, pictures)
            return
        }
        pending = nil
        ContentRules.apply(to: view.configuration.userContentController, pictures: pictures)
        // a new address for each document, so it is loaded again rather than taken from history
        shown += 1
        server.clear()
        view.load(URLRequest(url: server.serve(document, host: "preview", path: "\(shown)")))
    }

    /// the core's page for `state` (no message selected, downloading, why it could not be downloaded)
    func showState(_ state: PeReaderState, failure: PeFailureKind = PE_FAILURE_KIND_NONE, reason: String = "") {
        show(reason.withCString { taken(pe_reader_page(state, failure, $0)) } ?? "")
    }

    /// says that no message is selected, or shows nothing while one loads
    func clear(noMessage: Bool = true) {
        if noMessage {
            showState(PE_READER_STATE_NO_MESSAGE)
        } else {
            show("<!doctype html><html><head><meta name=\"color-scheme\" content=\"light\"><style>html{background:#fff}</style></head><body></body></html>")
        }
    }
}

// ---- the help ----

/// The help window: the core's help page for the Mac, shown like a message
@MainActor
final class HelpWindow: NSObject, NSWindowDelegate {
    static var shared: HelpWindow?
    let window: NSWindow
    private let preview = Preview()

    static func open() {
        if shared == nil {
            shared = HelpWindow()
        }
        shared?.window.makeKeyAndOrderFront(nil)
    }

    private override init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 640),
                          styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        window.title = Text.macHelpTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("help")
        window.isReleasedWhenClosed = false
        super.init()
        window.delegate = self
        window.contentView = preview.view
        if !TestHooks.testing {
            window.setFrameAutosaveName("Help")
        }
        if TestHooks.testing || !window.setFrameUsingName("Help") {
            window.center()
        }
        preview.show(taken(pe_help_page("mac")) ?? "<p>" + Text.macHelpMissing.text + "</p>")
    }

    func windowWillClose(_ notification: Notification) {
        HelpWindow.shared = nil
    }
}

// ---- printing ----

/// Prints a message as the reading pane shows it (with the pictures the user allowed): the same document in a web view
/// of its own, then the system's Print panel with its preview
@MainActor
final class Printer: NSObject {
    private static var current: Printer?
    private let server = DocumentServer()
    private let navigation = StayOnPage()
    private let view: WKWebView
    private let panel: NSWindow
    private weak var owner: NSWindow?

    static func print(_ document: String, pictures: Bool, title: String, owner: NSWindow?) {
        current = Printer(document, pictures: pictures, title: title, owner: owner)
    }

    private init(_ document: String, pictures: Bool, title: String, owner: NSWindow?) {
        self.owner = owner
        view = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 900),
                         configuration: lockedConfiguration(server: server, scripts: false))
        // printing needs the view in a window; this one is never shown
        panel = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.title = title
        panel.contentView = view
        super.init()
        view.navigationDelegate = navigation
        view.uiDelegate = navigation
        navigation.loaded = { [weak self] in self?.run() }
        ContentRules.whenReady { [weak self] in
            guard let self else { return }
            ContentRules.apply(to: view.configuration.userContentController, pictures: pictures)
            view.load(URLRequest(url: server.serve(document, host: "print", path: "1")))
        }
    }

    private func run() {
        navigation.loaded = nil
        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isVerticallyCentered = false
        let operation = view.printOperation(with: info)
        operation.jobTitle = panel.title
        operation.view?.frame = view.bounds
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        if let owner {
            operation.runModal(for: owner, delegate: self, didRun: #selector(done), contextInfo: nil)
        } else {
            operation.run()
            Printer.current = nil
        }
    }

    @objc private func done(_ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        Printer.current = nil
    }
}
