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

/// Serves the documents of a web view from memory, by the path of their address; the page of a signed or encrypted
/// message also its parts, each its frame's document (`part-N` beside the page's address), from the message's view;
/// and, with a core, the pictures of the previews after a message's text (`/pv/...`), which the core draws off the
/// main thread: their requests wait under their ask until its PreviewAnswered (`answered`)
final class DocumentServer: NSObject, WKURLSchemeHandler {
    private var documents: [String: Data] = [:]
    /// the parts of the page served last: under which path, and the document of part N (nil or empty for none)
    private var parts: (path: String, document: (Int) -> String?)?
    /// the core whose previews it serves (the reading pane's and a message window's); nil for none (printing)
    weak var core: Core? {
        didSet { Self.servers.add(self) }
    }
    /// the requests of preview pictures waiting for their answer, by ask; one WebKit stopped is taken out
    private var asks: [UInt64: WKURLSchemeTask] = [:]
    /// every server with a core, to find the one an answer is for
    private static let servers = NSHashTable<DocumentServer>.weakObjects()

    /// `html` at inboxclassic://<host>/<path>; its address. With `parts` the address ends in "/", and the page's
    /// frames ask for the parts beside it.
    func serve(_ html: String, host: String, path: String, parts: ((Int) -> String?)? = nil) -> URL {
        documents[host + "/" + path] = Data(html.utf8)
        self.parts = parts.map { (host + "/" + path + "/", $0) }
        return URL(string: "\(documentScheme)://\(host)/\(path)\(parts == nil ? "" : "/")")!
    }

    /// the documents served before, given up
    func clear() {
        documents.removeAll()
        parts = nil
    }

    /// a part of the page served last, asked for by its frame; nil for any other address
    private func part(_ url: URL, key: String) -> Data? {
        guard let parts, key.hasPrefix(parts.path) else { return nil }
        let index = url.absoluteString.withCString { pe_part_document($0) }
        guard index >= 0, let document = parts.document(Int(index)), !document.isEmpty else { return nil }
        return Data(document.utf8)
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, let host = url.host else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        // a preview's picture: the core only notes the ask here (quick), and draws it on a thread of its own
        if let core {
            let ask = url.absoluteString.withCString { pe_preview_ask(core.handle, $0) }
            if ask != 0 {
                asks[ask] = task
                return
            }
        }
        let key = host + "/" + url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let data = documents[key] ?? part(url, key: key) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        // never kept, as a part's document can carry decrypted text
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store"])!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    /// WebKit gave up a request (the document replaced, the window closed): its answer, should it come, is dropped, as
    /// WebKit raises on an answer to a stopped task
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        if let ask = asks.first(where: { $0.value === task })?.key {
            asks[ask] = nil
        }
    }

    /// PreviewAnswered for `ask`, on the main thread: the picture the core drew written to the request waiting for it,
    /// or "not found" (the view's previews ended); taken from the core all the same when no request waits anymore
    static func answered(_ ask: UInt64, core: Core) {
        let answer = pe_preview_answer(core.handle, ask)
        defer { pe_preview_answer_free(answer) }
        guard let server = servers.allObjects.first(where: { $0.asks[ask] != nil }),
              let task = server.asks.removeValue(forKey: ask) else { return }
        guard let picture = pe_preview_answer_picture(answer)?.pointee, let bytes = picture.bytes,
              let url = task.request.url else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": text(picture.mime_type), "Cache-Control": "no-store"])!
        task.didReceive(response)
        task.didReceive(Data(bytes: bytes, count: picture.length))
        task.didFinish()
    }
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
@MainActor
func openExternally(_ url: URL?) {
    guard let url, let scheme = url.scheme?.lowercased(), ["http", "https", "mailto"].contains(scheme) else { return }
    if let opened = TestHooks.openURL {
        opened(url)
        return
    }
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
    /// the document's first bytes are shown (before its frames and pictures are there)
    var committed: (() -> Void)?
    /// asked of a link clicked in the document before the browser opens it: true when its owner took it (the bounce
    /// card's), which the browser then does not open
    var links: ((String) -> Bool)?

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let scheme = action.request.url?.scheme?.lowercased() ?? ""
        // an inboxclassic: link of the document's own, which is no document's address (those have a host), should
        // one come other than as a click: never loaded; a preview's opens its file (its token checked)
        if scheme == documentScheme, action.navigationType != .linkActivated, let url = action.request.url, url.host == nil {
            decisionHandler(.cancel)
            if pe_reader_link(url.absoluteString) == PE_READER_LINK_ATTACHMENT {
                _ = links?(url.absoluteString)
            }
            return
        }
        // the document itself, and about:blank or about:srcdoc of its frames
        if (scheme == documentScheme && action.navigationType == .other) || scheme == "about" {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
        guard action.navigationType == .linkActivated, let url = action.request.url else { return }
        if links?(url.absoluteString) == true {
            return
        }
        if scheme != documentScheme {
            openExternally(url)
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

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        committed?()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded?()
    }
}

// ---- the reading pane ----

/// View > Text Size: the zoom of every web view that shows or writes a message (the reading pane, message windows,
/// the compose editor), set as each is made and again when the size changes. Their own zoom (pinch, Command and
/// the scroll wheel) is off, so the size changes only from the menu.
@MainActor
enum TextSize {
    /// the core's zoom for the size in use (pe_text_zoom)
    static var zoom: CGFloat = 1
    private static let views = NSHashTable<WKWebView>.weakObjects()

    static func register(_ view: WKWebView) {
        view.allowsMagnification = false
        view.pageZoom = zoom
        views.add(view)
    }

    static func apply(_ zoom: CGFloat) {
        Self.zoom = zoom
        for view in views.allObjects {
            view.pageZoom = zoom
        }
        // the stack's frames as tall as their documents in the new size
        Preview.textSizeChanged()
    }
}

/// The message bodies: the sanitized documents of the core (pe_html_render), shown as they are, scripts off
@MainActor
final class Preview: NSObject {
    let view: WKWebView
    private let server = DocumentServer()
    private let navigation = StayOnPage()
    private var shown = 0
    private var pending: (document: String, pictures: Bool, parts: ((Int) -> String?)?)?
    private var ready = false
    /// a document is shown in a frame of the stack (`fitted`), measured as it changes
    private var measuring = false
    /// measured every 400 ms from the moment the document is asked for, the page loads, its width or the text size
    /// changes or it is clicked ("..." unfolded), until its height stays the same `settled` times running
    private var measureTimer: Timer?
    /// how many readings running found the height the one before found, and that height (in the page's points)
    private var unchanged = 0
    private var lastHeight = 0.0
    private static let settled = 5
    /// every preview, to measure their documents again when the text size changes
    private static let all = NSHashTable<Preview>.weakObjects()
    /// Settings' dark messages: whether the blank page between two messages may be dark too. The web views follow the
    /// window's appearance (WebKit draws their background dark before a document loads); the documents carry both looks.
    static var dark = false
    /// a frame of the reading pane's stack (ConversationStack): the document's height in points, measured as it loads
    /// and while it is shown (pictures arriving, the width or the text size changing); the web view is made that tall
    /// and passes the wheel to the stack, so it never scrolls by itself
    var fitted: ((CGFloat) -> Void)? {
        didSet { (view as? ReadingView)?.fitsContent = fitted != nil }
    }
    /// asked of a link clicked in the document before the browser opens it: true when the reading pane took it
    var links: ((String) -> Bool)? {
        get { navigation.links }
        set { navigation.links = newValue }
    }

    /// the core whose previews the documents show (pictures and PDF files after a message's text)
    weak var core: Core? {
        get { server.core }
        set { server.core = newValue }
    }
    /// the preview token of the document shown (`preview_token`), ended when another document replaces it
    private var previewToken = ""

    override init() {
        view = ReadingView(frame: .zero, configuration: lockedConfiguration(server: server, scripts: false))
        super.init()
        view.navigationDelegate = navigation
        view.uiDelegate = navigation
        view.allowsBackForwardNavigationGestures = false
        TextSize.register(view)
        view.isInspectable = false
        view.setAccessibilityIdentifier("preview")
        // every picture is there (or failed): the height they make
        navigation.loaded = { [weak self] in self?.remeasure() }
        navigation.committed = { [weak self] in self?.remeasure() }
        (view as? ReadingView)?.changed = { [weak self] in self?.remeasure() }
        Self.all.add(self)
        ContentRules.whenReady { [weak self] in
            guard let self else { return }
            ready = true
            if let pending {
                show(pending.document, pictures: pending.pictures, parts: pending.parts, previews: previewToken)
            } else {
                clear()
            }
        }
    }

    deinit {
        measureTimer?.invalidate()
        if let core = server.core, !previewToken.isEmpty {
            previewToken.withCString { pe_previews_end(core.handle, $0) }
        }
    }

    /// the previews of the document shown given up: the core draws and answers none of them anymore
    private func endPreviews() {
        if let core, !previewToken.isEmpty {
            previewToken.withCString { pe_previews_end(core.handle, $0) }
        }
        previewToken = ""
    }

    /// a document of the core; with `pictures` its pictures from the internet are let through. A signed or encrypted
    /// message's page has `parts`, the document of each of its frames, served beside it. `previews` is the view's
    /// preview token (empty for none): the previews of the document before are ended. In a frame of the stack
    /// (`fitted`) the document is measured from the moment it is asked for until its height settles.
    func show(_ document: String, pictures: Bool = false, parts: ((Int) -> String?)? = nil, previews: String = "") {
        stopMeasuring()
        if previews != previewToken {
            endPreviews()
            previewToken = previews
        }
        guard ready else {
            pending = (document, pictures, parts)
            return
        }
        pending = nil
        ContentRules.apply(to: view.configuration.userContentController, pictures: pictures)
        // a new address for each document, so it is loaded again rather than taken from history
        shown += 1
        server.clear()
        view.load(URLRequest(url: server.serve(document, host: "preview", path: "\(shown)", parts: parts)))
        if fitted != nil {
            measuring = true
            remeasure()
        }
    }

    // ---- a frame of the stack, as tall as its document ----

    /// the document measured at once, and every 400 ms until its height stays the same `settled` times running: the
    /// page shown (its frames sized at once, as every picture's size is in the parts' markup, rather than after the
    /// pictures arrived), loaded, wider or narrower, in another text size, or clicked ("..." unfolded)
    private func remeasure() {
        guard measuring else { return }
        unchanged = 0
        measure()
        guard measureTimer == nil else { return }
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else {
                    timer.invalidate()
                    return
                }
                self.measure()
            }
        }
        // on also while a modal window or a menu runs
        RunLoop.main.add(timer, forMode: .common)
        measureTimer = timer
    }

    /// the height settled: no more readings until something changes it
    private func settle() {
        measureTimer?.invalidate()
        measureTimer = nil
    }

    private func stopMeasuring() {
        measuring = false
        lastHeight = 0
        settle()
    }

    /// one reading more of the same height (or none to take, out of a window), toward settling
    private func sameReading() {
        unchanged += 1
        if unchanged >= Self.settled {
            settle()
        }
    }

    /// the core's script run in the page, in the app's own world: the page's scripts stay off
    /// (allowsContentJavaScript), and the app's script sees the page and its frames but none of their globals. It
    /// sizes the parts' frames, then says the document's height.
    private func measure() {
        guard view.window != nil else {
            // measured again once it is in a window (ReadingView's `changed`)
            sameReading()
            return
        }
        view.evaluateJavaScript(Self.heightScript, in: nil, in: .defaultClient) { [weak self] result in
            guard let self, measuring, let fitted, let height = ((try? result.get()) as? NSNumber)?.doubleValue,
                  height > 0 else { return }
            if height == lastHeight {
                sameReading()
            } else {
                lastHeight = height
                unchanged = 0
            }
            fitted(CGFloat(height) * view.pageZoom)
        }
    }

    static let heightScript = String(cString: pe_height_script())

    /// View > Text Size: the documents of the stack's frames measured again
    static func textSizeChanged() {
        for preview in all.allObjects {
            preview.remeasure()
        }
    }

    /// what a script of the app's own (`script`, an expression) says of the page, as a string; for the UI test
    func pageAnswer(_ script: String) async -> String {
        await withCheckedContinuation { done in
            view.evaluateJavaScript("String(\(script))", in: nil, in: .defaultClient) { result in
                done.resume(returning: (try? result.get()) as? String ?? "")
            }
        }
    }

    /// the core's page for `state` (no message selected, downloading, why it could not be downloaded)
    func showState(_ state: PeReaderState, failure: PeFailureKind = PE_FAILURE_KIND_NONE, reason: String = "", size: UInt64 = 0) {
        show(reason.withCString { taken(pe_reader_page(state, failure, $0, size)) } ?? "")
    }

    /// says that no message is selected, or shows nothing while one loads
    func clear(noMessage: Bool = true) {
        if noMessage {
            showState(PE_READER_STATE_NO_MESSAGE)
        } else {
            // as dark as the message coming will be (pe_html's dark colors), so nothing flashes white
            let (scheme, dark) = Preview.dark
                ? ("light dark", "@media screen and (prefers-color-scheme:dark){html{background:#1e1f22}}") : ("light", "")
            show("<!doctype html><html><head><meta name=\"color-scheme\" content=\"\(scheme)\">"
                + "<style>html{background:#fff}\(dark)</style></head><body></body></html>")
        }
    }
}

/// The web view of the reading pane and a message's window: its context menu without what would open a window or
/// download, which a message's web view never does. A preview's picture is the core's copy, not the file, so its
/// Download Image or Open Image would not be the file either; its link opens the file, as Open Link does.
final class ReadingView: WKWebView {
    /// a frame of the reading pane's stack: as tall as its document, the wheel's vertical turns scroll the stack
    var fitsContent = false
    /// a click in the document: the stack selects the frame's message
    var clicked: (() -> Void)?
    /// its document may be another height now: the width changed (it wraps anew), it was put in a window, or it was
    /// clicked ("..." unfolded)
    var changed: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        clicked?()
        super.mouseDown(with: event)
        changed?()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            changed?()
        }
    }

    override func scrollWheel(with event: NSEvent) {
        if fitsContent, abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX), let outer = enclosingScrollView {
            outer.scrollWheel(with: event)
            return
        }
        super.scrollWheel(with: event)
    }

    override func setFrameSize(_ newSize: NSSize) {
        let widthChanged = newSize.width != frame.width
        super.setFrameSize(newSize)
        if widthChanged {
            changed?()
        }
    }

    /// WebKit's names of the items taken out
    static let notOffered = ["DownloadImage", "OpenImageInNewWindow", "OpenLinkInNewWindow", "DownloadLinkedFile",
                               "OpenFrameInNewWindow"]

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        for item in menu.items.reversed() {
            let name = item.identifier?.rawValue ?? ""
            if Self.notOffered.contains(where: { name.contains($0) }) {
                menu.removeItem(item)
            }
        }
        TestHooks.webMenu?(menu)
        super.willOpenMenu(menu, with: event)
    }
}

// ---- the help ----

/// The help: the Help Book in the bundle (Contents/Resources/InboxClassic.help, which scripts/mac-build.sh makes of
/// the core's topics), shown by Help Viewer, whose search the Help menu has too
@MainActor
enum Help {
    /// the windows with a topic of their own (help/topics.toml [context]); every other one opens the main window's
    static let contexts = [
        "account.start": "account-form", "accounts": "account-properties", "settings": "options",
        "signin.apps": "sign-in-apps", "signin.editor": "sign-in-apps", "agents": "agents", "addressbook": "address-book",
        "contact": "address-book", "group": "address-book", "pick": "address-book", "compose": "compose",
        "keys": "encryption-keys", "key.new": "encryption-keys", "key.backup": "encryption-keys",
        "key.import": "encryption-keys", "key.properties": "encryption-keys", "account.security": "encryption-keys",
        "key.verify": "verify-key", "protection.details": "protection-details", "recipient.keys": "recipient-keys",
        "setup.export": "setup", "setup.import": "setup", "setup.passphrase": "setup", "setup.done": "setup",
    ]

    /// opens the help at the topic of `context` (`main`, `account-form`, `options`, ...)
    static func open(_ context: String) {
        let anchor = taken(pe_help_context(context)) ?? "main-window"
        if let asked = TestHooks.help {
            asked(anchor)
            return
        }
        let book = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String
        NSHelpManager.shared.openHelpAnchor(anchor, inBook: book)
    }

    /// Help in the menu (⌘?): the topic of the window in front
    static func open(for window: NSWindow?) {
        open(contexts[window?.identifier?.rawValue ?? ""] ?? "main")
    }
}

/// The round help button of a window, which opens the window's topic
@MainActor
final class HelpButton: NSButton {
    private var context = ""

    convenience init(_ context: String) {
        self.init(frame: .zero)
        self.context = context
        bezelStyle = .helpButton
        title = ""
        target = self
        action = #selector(clicked)
        setAccessibilityIdentifier("help.\(context)")
        // AppKit's own name for it is English
        setAccessibilityLabel(Text.menuHelp.text)
        toolTip = Text.menuHelp.text
        setContentHuggingPriority(.required, for: .horizontal)
    }

    @objc private func clicked() {
        Help.open(context)
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

    /// the page of a signed or encrypted message with its `parts`, each frame then as tall as its part
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
        // paper is light: the documents' dark colors apply to a dark screen only, and the view is never dark either
        panel.appearance = NSAppearance(named: .aqua)
        view.appearance = NSAppearance(named: .aqua)
        super.init()
        view.navigationDelegate = navigation
        view.uiDelegate = navigation
        view.configuration.userContentController.addUserScript(Printer.syncPictures)
        // didFinish comes after the load event, so every picture is loaded (or failed)
        navigation.loaded = { [weak self] in
            self?.navigation.loaded = nil
            self?.run()
        }
        ContentRules.whenReady { [weak self] in
            guard let self else { return }
            ContentRules.apply(to: view.configuration.userContentController, pictures: pictures)
            view.load(URLRequest(url: server.serve(document, host: "print", path: "1")))
        }
    }

    /// WebKit draws a picture on paper only when no decode of it is under way on its decoding threads: while one is,
    /// it draws nothing there and the picture prints as an empty box. The view's own paint (it is never shown) starts
    /// such a decode for a picture it does not count as visible, and so does img.decode(), whose promise is kept by
    /// any decode of the picture that ends, even the view's smaller one while its own is still queued. Every picture
    /// of the page is made decoding="sync" as the parser puts it in, before anything is painted, so no paint starts
    /// one: the app's own script, in its own world (the page runs none), at the start of the document
    private static let syncPictures = WKUserScript(
        source: "new MutationObserver(changes => { for (const change of changes) for (const node of change.addedNodes) {"
            + " if (node.nodeType !== 1) continue; if (node.localName === 'img') node.decoding = 'sync';"
            + " for (const img of node.getElementsByTagName('img')) img.decoding = 'sync' } })"
            + ".observe(document, { childList: true, subtree: true })",
        injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .defaultClient)

    private func run() {
        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isVerticallyCentered = false
        // the UI test prints to a file, without the Print panel
        let file = TestHooks.printTo
        if let file {
            info.jobDisposition = .save
            info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = file
        }
        let operation = view.printOperation(with: info)
        operation.jobTitle = panel.title
        operation.view?.frame = view.bounds
        operation.showsPrintPanel = file == nil
        operation.showsProgressPanel = file == nil
        if let owner {
            operation.runModal(for: owner, delegate: self, didRun: #selector(done), contextInfo: nil)
        } else {
            operation.run()
            Printer.current = nil
        }
    }

    @objc private func done(_ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        Printer.current = nil
        TestHooks.printed?(success)
    }
}
