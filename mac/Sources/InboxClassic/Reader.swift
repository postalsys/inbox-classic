// The reading pane: the header of the message (From, Date, To, Cc, Subject) with the brand's logo at its left and the
// attachments and Unsubscribe at its right; under it the bar that offers the pictures from the internet; then the
// message itself, with the cards of the core above it (a calendar event, a bounce, a one-time code). Every string shown is the core's, decoded and checked there.
// It asks the core for the message it shows and hears its events, so the main window's pane and a message's own window
// (MessageWindow.swift) are each one of these.
import AppKit
import CInboxClassic
import WebKit

@MainActor
final class Reader: NSObject {
    let view = NSStackView()
    let core: Core
    /// what it has to say in the main window's status bar (leaving a mailing list)
    var status: (String) -> Void = { _ in }
    /// a mailto: link to write a message for (a mailing list left by mail)
    var openMailto: (String) -> Void = { _ in }
    /// the message asked for is here, before it is shown (a draft opened before it was fetched opens then)
    var arrivedHandler: () -> Void = {}
    /// the message is shown
    var shownHandler: () -> Void = {}
    /// "Show the message that bounced" on a bounce's card: the message it returns, to select in its folder
    var bouncedHandler: (_ folder: Int64, _ uid: UInt64) -> Void = { _, _ in }
    /// the message shown, or asked for; 0 for none
    private(set) var folder: Int64 = 0
    private(set) var uid: UInt64 = 0
    /// the account of that message, which its sync tries a failed download again for
    private var account: Int64 = 0
    /// the core's view of the message once it is shown
    private(set) var messageView: MessageView?
    /// a message file (.eml) shown, of no folder, instead of a message of the store
    private(set) var file: String?
    /// the size of the message asked for, from the list, for the page shown while it is downloaded
    private var loadingSize: UInt64 = 0
    /// its pictures from the internet were asked for
    private(set) var remoteImages = false
    /// a download asked for and not answered yet: MessageReady or MessageFailed for it is this reader's
    private var waiting = false
    private var viewRequest: UInt64 = 0
    private var logoRequest: UInt64 = 0
    /// without a logo, the sender's picture from the Address Book drawn for the logo's place
    private var pictureRequest: UInt64 = 0
    private var unsubscribeRequest: UInt64 = 0
    private let preview = Preview()
    /// Find in This Message: a bar over the message, as Safari and Mail have
    private let findBar = FindBar()
    private let header = HeaderText(wrappingLabelWithString: "")
    private let logo = NSImageView()
    /// the header and the line under it, shown only over a message
    private let headerBox = NSView()
    private let headerLine = NSBox()
    private let attachments = NSPopUpButton(frame: .zero, pullsDown: true)
    private let unsubscribe = NSButton(title: Text.uiUnsubscribe.text, target: nil, action: nil)
    private let pictures = InfoBar(icon: "image", link: nil)
    /// the bar's Download Pictures with its menu: the Always choices for a sender the provider confirmed, the
    /// greyed line that says why there are none for one it did not
    let picturesChoices = NSComboButton()
    /// the bar's Download Pictures alone, for a message without a single sender
    let picturesDownload = NSButton()
    /// over a message that could not be downloaded: Try Again
    private let retry = InfoBar(icon: "arrow_sync", link: nil, button: Text.uiTryAgain.text)
    /// a moment after a message is asked for, the pane says it is being downloaded (one that is cached shows first)
    private var downloadingTimer: Timer?
    private(set) var picturesOffered = false
    /// over several messages: the numbers the core's page shows
    private var summary: PeSelectionSummary?
    /// the logo's side in pixels, for the core to draw it at
    var logoPixels: Int { Int(48 * (view.window?.backingScaleFactor ?? 2)) }

    init(core: Core) {
        self.core = core
        super.init()
        header.isSelectable = true
        header.setAccessibilityIdentifier("reader.header")
        header.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // below the stack's own 250, so it takes the free width and the files sit at the trailing edge
        header.setContentHuggingPriority(.init(249), for: .horizontal)
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
        right.setContentHuggingPriority(.required, for: .horizontal)
        let top = NSStackView(views: [logo, header, right])
        top.alignment = .top
        top.spacing = 10
        top.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        top.translatesAutoresizingMaskIntoConstraints = false
        headerBox.addSubview(top)
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: headerBox.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: headerBox.trailingAnchor),
            top.topAnchor.constraint(equalTo: headerBox.topAnchor),
            top.bottomAnchor.constraint(equalTo: headerBox.bottomAnchor),
            // the same 8pt under the text with a logo as without, and never shorter than the logo
            header.bottomAnchor.constraint(lessThanOrEqualTo: headerBox.bottomAnchor, constant: -8),
            logo.bottomAnchor.constraint(lessThanOrEqualTo: headerBox.bottomAnchor, constant: -8),
        ])
        headerLine.boxType = .separator

        pictures.text = Text.uiPicturesBlocked.text
        pictures.clicked = { [weak self] in self?.loadPictures() }
        pictures.setAccessibilityIdentifier("reader.pictures")
        setUpPicturesButtons()
        retry.text = taken(pe_retry_note()) ?? ""
        retry.clicked = { [weak self] in self?.retryDownload() }
        retry.setAccessibilityIdentifier("reader.retry")
        retry.isHidden = true
        // the links of the document's own cards: the core says which link it is, the view has what it needs
        preview.links = { [weak self] link in self?.followLink(link) ?? false }
        pictures.isHidden = true

        view.orientation = .vertical
        view.spacing = 0
        view.alignment = .leading
        findBar.find = { [weak self] words, backwards, done in self?.find(words, backwards: backwards, done: done) }
        findBar.closed = { [weak self] in
            guard let self else { return }
            view.window?.makeFirstResponder(preview.view)
        }
        for part in [headerBox, headerLine, retry, pictures, findBar, preview.view] as [NSView] {
            view.addArrangedSubview(part)
            part.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        }
        view.setHuggingPriority(.defaultLow, for: .vertical)
        preview.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        pictures.heightAnchor.constraint(equalToConstant: 28).isActive = true
        retry.heightAnchor.constraint(equalToConstant: 34).isActive = true
        findBar.heightAnchor.constraint(equalToConstant: 36).isActive = true
        clearView(loading: false)
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

    private func clearView(loading: Bool) {
        summary = nil
        downloadingTimer?.invalidate()
        retry.isHidden = true
        header.stringValue = ""
        // no empty band over the pane's "no message" or several messages' page; a message about to load keeps it
        showHeader(loading)
        // the bars of the message before stay while the next one loads, and go when it is there without them
        if !loading {
            attachments.isHidden = true
            pictures.isHidden = true
            picturesOffered = false
        }
        unsubscribe.isHidden = true
        logo.isHidden = true
        logo.image = nil
        // says so rather than a blank pane, unless a message is about to be shown
        preview.clear(noMessage: !loading)
    }

    private func showHeader(_ shown: Bool) {
        headerBox.isHidden = !shown
        headerLine.isHidden = !shown
    }

    /// a message asked for: its header from the list at once, and after a moment, should it not be here yet, that it is
    /// being downloaded
    func showLoading(_ row: Message) {
        loadingSize = row.size
        showHeader(true)
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
        // how large it is, too
        preview.showState(PE_READER_STATE_DOWNLOADING, size: loadingSize)
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
        showHeader(true)
        header.stringValue = problem
        attachments.isHidden = true
        pictures.isHidden = true
        picturesOffered = false
    }

    private func show(_ info: PeMessageInfo, view: MessageView) {
        downloadingTimer?.invalidate()
        retry.isHidden = true
        showHeader(true)
        header.attributedStringValue = headerText(info)
        let files = info.attachment_count
        attachments.isHidden = files == 0
        attachments.removeAllItems()
        // the title item of a pull-down button: the paper clip and how many files there are
        attachments.addItem(withTitle: Text.macFiles.text(["count": files]))
        attachments.item(at: 0)?.image = Icons.list("attach")
        // a mailing list that says how to leave it
        unsubscribe.isHidden = info.unsubscribe == PE_UNSUBSCRIBE_NONE || file != nil
        // asked for, or loaded by themselves (Settings, a trusted sender the provider confirmed): the core says
        let allowed = info.pictures_loaded || remoteImages
        preview.show(text(info.document), pictures: allowed)
        // offered only for a message with pictures on the internet, until they are shown
        picturesOffered = info.remote_images && !allowed
        pictures.isHidden = !picturesOffered
        if picturesOffered {
            offerPictures(info)
        }
    }

    // ---- the pictures bar ----

    private func setUpPicturesButtons() {
        let label = Command.pictures.label
        picturesChoices.title = label
        picturesChoices.style = .split
        picturesChoices.controlSize = .small
        // the combo button keeps the regular font at the small size: the plain button's, so the two match
        picturesChoices.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
        picturesChoices.target = self
        picturesChoices.action = #selector(downloadClicked)
        picturesChoices.menu = NSMenu()
        picturesChoices.setAccessibilityIdentifier("reader.pictures.choices")
        picturesDownload.title = label
        picturesDownload.bezelStyle = .push
        picturesDownload.controlSize = .small
        picturesDownload.target = self
        picturesDownload.action = #selector(downloadClicked)
        picturesDownload.setAccessibilityIdentifier("reader.pictures.download")
        pictures.setAccessories([picturesChoices, picturesDownload])
    }

    /// the bar for this message, as on Windows: Download Pictures with a menu when there is a sender, of Always from
    /// them and from everyone at their domain when the provider confirmed them, otherwise of Download Pictures and
    /// the greyed line that says why there is no Always; without a sender Download Pictures alone
    private func offerPictures(_ info: PeMessageInfo) {
        let always = [(text(info.pictures_always_sender), "sender"), (text(info.pictures_always_domain), "domain")]
            .filter { !$0.0.isEmpty }
        let unconfirmed = text(info.pictures_unconfirmed)
        let menu = picturesChoices.menu
        menu.removeAllItems()
        for (title, kind) in always {
            let item = NSMenuItem(title: title, action: #selector(alwaysChosen(_:)), keyEquivalent: "")
            item.target = self
            item.tag = kind == "domain" ? 1 : 0
            item.setAccessibilityIdentifier("pictures.always.\(kind)")
            menu.addItem(item)
        }
        if always.isEmpty && !unconfirmed.isEmpty {
            let download = NSMenuItem(title: Command.pictures.label, action: #selector(downloadClicked),
                                      keyEquivalent: "")
            download.target = self
            download.setAccessibilityIdentifier("pictures.download")
            menu.addItem(download)
            menu.addItem(.separator())
            menu.addItem(unconfirmedItem(unconfirmed))
        }
        let split = !text(info.sender).isEmpty && menu.numberOfItems > 0
        picturesChoices.isHidden = !split
        picturesDownload.isHidden = split
    }

    /// the greyed line of the menu that says why the sender could not be confirmed: wrapped at a menu's width, its
    /// whole text as its tooltip
    private func unconfirmedItem(_ note: String) -> NSMenuItem {
        let item = NSMenuItem(title: note, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.toolTip = note
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        let font = NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)
        let attributed = NSAttributedString(string: note, attributes: [
            .font: font, .foregroundColor: NSColor.disabledControlTextColor, .paragraphStyle: style,
        ])
        let label = NSTextField(labelWithAttributedString: attributed)
        label.maximumNumberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        label.preferredMaxLayoutWidth = 320
        let size = label.sizeThatFits(NSSize(width: 320, height: 1000))
        let box = NSView(frame: NSRect(x: 0, y: 0, width: ceil(size.width) + 28, height: ceil(size.height) + 6))
        label.frame = NSRect(x: 14, y: 3, width: ceil(size.width), height: ceil(size.height))
        box.addSubview(label)
        box.toolTip = note
        item.view = box
        item.setAccessibilityIdentifier("pictures.unconfirmed")
        return item
    }

    @objc private func downloadClicked() {
        loadPictures()
    }

    /// Always download pictures from the sender (tag 0) or from everyone at their domain (tag 1): the sender
    /// trusted, and this message's pictures shown
    @objc private func alwaysChosen(_ sender: NSMenuItem) {
        guard let info = messageView?.info?.pointee else { return }
        let domain = sender.tag == 1
        let value = text(domain ? info.sender_domain : info.sender)
        guard !value.isEmpty, core.trustSender(value, domain: domain) else { return }
        loadPictures()
    }

    /// the menu of the bar's Download Pictures, for the UI test
    var picturesMenu: NSMenu? { picturesChoices.isHidden ? nil : picturesChoices.menu }

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

    /// the brand's logo as it is, or a person's picture `round` as the list shows it
    func showLogo(_ pixels: Data?, round: Bool = false) {
        guard let image = pixelImage(pixels, side: logoPixels, points: 48) else { return }
        logo.image = round ? roundImage(image) : image
        logo.isHidden = false
    }

    @objc private func unsubscribeClicked() {
        unsubscribeList()
    }

    // ---- the message it shows ----

    /// no message (`loading`: one is about to be asked for); a view being made for the one before is given up
    func clear(loading: Bool) {
        if viewRequest != 0 {
            pe_message_view_cancel(core.handle, viewRequest)
            viewRequest = 0
        }
        folder = 0
        uid = 0
        account = 0
        waiting = false
        remoteImages = false
        messageView = nil
        file = nil
        logoRequest = 0
        pictureRequest = 0
        clearView(loading: loading)
    }

    /// the message `uid` of `folder` (of `account`) asked for: the header of its row (`row`) at once, the message when
    /// MessageReady follows (right away when it is cached), or why not when MessageFailed does
    func open(folder id: Int64, uid message: UInt64, account owner: Int64, row: Message?) {
        clear(loading: true)
        folder = id
        uid = message
        account = owner
        if let row {
            showLoading(row)
        }
        waiting = true
        pe_message_open(core.handle, id, message)
    }

    /// Try Again, or the account synced again after the message could not be downloaded
    func retryDownload() {
        guard uid != 0 else { return }
        showDownloading()
        waiting = true
        pe_message_open(core.handle, folder, uid)
    }

    /// the pictures from the internet shown, as the user asked
    func loadPictures() {
        guard showsMessage && !remoteImages else { return }
        remoteImages = true
        reload()
    }

    var picturesBlocked: Bool { showsMessage && !remoteImages && picturesOffered }

    /// the message shown made again: Settings' pictures or trusted senders changed
    func reload() {
        guard showsMessage else { return }
        if file != nil {
            _ = showFile()
        } else {
            makeView()
        }
    }

    /// a message is shown, of a folder or a file
    private var showsMessage: Bool { (uid != 0 || file != nil) && messageView != nil }

    /// the message file at `path` (.eml, opened from the Finder) shown; nil when it is, otherwise why not
    func open(file path: String) -> String? {
        clear(loading: true)
        file = path
        return showFile()
    }

    /// the core reads the file into a view at once: it is the user's own, on their disk
    private func showFile() -> String? {
        guard let file else { return nil }
        var error: UnsafeMutablePointer<CChar>?
        let made = MessageView(file.withCString { pe_file_view(core.handle, $0, remoteImages, &error) })
        let reason = taken(error)
        guard let made, let info = made.info else {
            clear(loading: false)
            return reason ?? Text.uiNotShown.text
        }
        messageView = made
        show(info.pointee, view: made)
        shownHandler()
        return nil
    }

    /// parsing, folding and sanitizing a large message takes a while: on a worker, ViewReady follows
    private func makeView() {
        if viewRequest != 0 {
            pe_message_view_cancel(core.handle, viewRequest)
        }
        viewRequest = pe_message_view_start(core.handle, folder, uid, remoteImages)
        if viewRequest == 0 {
            showProblem(Text.uiNotShown.text)
        }
    }

    private func showView() {
        messageView = MessageView(pe_message_view_result(core.handle, viewRequest))
        viewRequest = 0
        guard let messageView, let info = messageView.info else {
            showProblem(Text.uiNotShown.text)
            return
        }
        show(info.pointee, view: messageView)
        if info.pointee.has_logo {
            logoRequest = pe_logo_start(core.handle, folder, uid, UInt32(logoPixels))
        } else if info.pointee.picture != 0 {
            pictureRequest = pe_picture_start(core.handle, info.pointee.picture, UInt32(logoPixels))
        }
        shownHandler()
    }

    /// the core's events about the message: here, not here, its view made, its logo drawn, its account back
    func onEvent(_ event: CoreEvent) {
        switch event.kind {
        case PE_EVENT_KIND_MESSAGE_READY:
            // another window may have asked for the same message: only an answer this one waits for
            if waiting && event.folder == folder && event.uid == uid {
                waiting = false
                arrived()
                arrivedHandler()
                makeView()
            }
        case PE_EVENT_KIND_MESSAGE_FAILED:
            if waiting && event.folder == folder && event.uid == uid {
                waiting = false
                showFailed(kind: event.failure, reason: event.message)
            }
        case PE_EVENT_KIND_VIEW_READY:
            // a view for a message that is no longer shown was cancelled, its event is not this one
            if viewRequest != 0 && event.uid == viewRequest {
                showView()
            }
        case PE_EVENT_KIND_LOGO_READY:
            if logoRequest != 0 && event.uid == logoRequest {
                logoRequest = 0
                var length = 0
                showLogo(takenBytes(pe_logo_result(core.handle, event.uid, &length), length))
            }
        case PE_EVENT_KIND_PICTURE_READY:
            if pictureRequest != 0 && event.uid == pictureRequest {
                pictureRequest = 0
                var length = 0
                showLogo(takenBytes(pe_picture_result(core.handle, event.uid, &length), length), round: true)
            }
        case PE_EVENT_KIND_SYNC_FINISHED:
            // the account is back: a message it could not give is tried again
            if event.failure == PE_FAILURE_KIND_NONE, showsFailure, account == event.account {
                retryDownload()
            }
        default:
            break
        }
    }

    /// a link clicked in the message: true when it is one of the document's own cards, which this follows (the bounce
    /// card's message selected, the code card's Copy), false for a link of the message (the browser opens it)
    func followLink(_ link: String) -> Bool {
        switch pe_reader_link(link) {
        case PE_READER_LINK_BOUNCED_MESSAGE:
            showBounced()
            return true
        case PE_READER_LINK_COPY_CODE:
            copyCode()
            return true
        case PE_READER_LINK_OPEN_CALENDAR:
            openInCalendar()
            return true
        default:
            return false
        }
    }

    /// the code card's Copy: the code the core found, on the clipboard (nothing is read from the link)
    private func copyCode() {
        guard let info = messageView?.info?.pointee, let pointer = info.otp_code else { return }
        let code = String(cString: pointer)
        guard !code.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        status(Text.uiCodeCopied.text)
    }

    /// the card's link was clicked: the message the bounce shown returns, where the core found it (nothing is read
    /// from the link)
    private func showBounced() {
        guard let info = messageView?.info?.pointee, info.has_bounced_message else { return }
        bouncedHandler(info.bounced_folder, info.bounced_uid)
    }

    /// a reply, a reply to all or a forward of the message shown; of a message file from `account`
    func draft(_ kind: PeDraftKind, account from: Int64 = 0) -> Draft? {
        guard showsMessage else { return nil }
        if let file {
            return file.withCString { Draft(pe_file_draft(core.handle, $0, from, kind)) }
        }
        return Draft(pe_message_draft(core.handle, folder, uid, kind))
    }

    /// the message as it is shown, with the pictures it shows
    func print() {
        guard showsMessage, let info = messageView?.info else { return }
        Printer.print(text(info.pointee.document), pictures: info.pointee.pictures_loaded || remoteImages,
                      title: text(info.pointee.subject), owner: view.window)
    }

    // ---- Find in This Message ----

    /// Find in This Message: the find bar over the message opened, its words selected to type over
    func findCommand() {
        guard messageView != nil else { return }
        findBar.open()
    }

    /// the words of the find bar looked for in the message, by the web view's own find (no script runs in the
    /// message), after the place found last or before it (`backwards`); whether they are there
    private func find(_ words: String, backwards: Bool, done: @escaping (Bool) -> Void) {
        let configuration = WKFindConfiguration()
        configuration.wraps = true
        configuration.backwards = backwards
        preview.view.find(words, configuration: configuration) { result in done(result.matchFound) }
    }

    /// the subject of the message shown, empty before it is
    var subject: String { messageView?.info.map { text($0.pointee.subject) } ?? "" }

    // ---- attachments ----

    /// the files of the message to save, then all of them into a folder; files are saved, never opened from here
    func attachmentMenu() -> NSMenu {
        let menu = NSMenu()
        guard let view = messageView, let info = view.info else { return menu }
        for index in 0..<info.pointee.attachment_count {
            guard let attachment = view.attachment(index) else { continue }
            let item = NSMenuItem(title: "\(attachment.name) (\(formatSize(attachment.size)))",
                                  action: #selector(saveAttachment(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let all = NSMenuItem(title: Text.macSaveAttachmentsMenu.text, action: #selector(saveAllAttachments), keyEquivalent: "")
        all.target = self
        menu.addItem(all)
        return menu
    }

    @objc private func saveAttachment(_ sender: NSMenuItem) {
        var length = 0
        var name: UnsafeMutablePointer<CChar>?
        // the core reads it from the store, or from the message file shown
        let bytes = file.map { path in
            path.withCString { pe_file_attachment_data(core.handle, $0, sender.tag, &length, &name) }
        } ?? pe_attachment_data(core.handle, folder, uid, sender.tag, &length, &name)
        let data = takenBytes(bytes, length)
        let safeName = taken(name) ?? "attachment"
        guard let data else {
            // a large message shows its text before the rest of it is here
            if file == nil && pe_message_downloading(core.handle, folder, uid) {
                inform(Text.uiAttachmentDownloading.text)
            } else {
                inform(Text.uiAttachmentNotRead.text, style: .error)
            }
            return
        }
        if let url = saveFilePanel(name: safeName), !writeDownloaded(data, to: url) {
            inform(Text.uiAttachmentNotSaved.text, style: .error)
        }
    }

    @objc private func saveAllAttachments() {
        guard let into = folderPanel(title: Text.uiSaveAttachments.text) else { return }
        // the core saves them all from one reading of the message, a file already there kept and the new one numbered
        var saved = 0
        var total = 0
        let done = into.path.withCString { dir in
            file.map { path in path.withCString { pe_file_save_attachments(core.handle, $0, dir, &saved, &total) } }
                ?? pe_save_attachments(core.handle, folder, uid, dir, &saved, &total)
        }
        if !done {
            inform(Text.uiNotDownloaded.text)
        } else if saved < total {
            inform(Text.macFilesNotSaved.text(["failed": total - saved, "count": total]), style: .error)
        }
    }

    /// the calendar part as a file of its own (the core writes it, and only it), for the calendar app
    func openInCalendar() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("InboxClassic/Invitations").path
        // the core reads it from the store, or from the message file shown
        let written = dir.withCString { dir in
            file.map { path in path.withCString { pe_file_invitation_file(core.handle, $0, dir) } }
                ?? pe_invitation_file(core.handle, folder, uid, dir)
        }
        guard let path = taken(written) else {
            inform(Text.uiInvitationNotRead.text, style: .error)
            return
        }
        if !NSWorkspace.shared.open(URL(fileURLWithPath: path)) {
            inform(Text.macNoCalendarApp.text)
        }
    }

    // ---- leaving a mailing list ----

    func unsubscribeList() {
        guard let info = messageView?.info?.pointee else { return }
        let target = text(info.unsubscribe_target)
        let link = text(info.unsubscribe_link)
        switch info.unsubscribe {
        case PE_UNSUBSCRIBE_ONE_CLICK:
            guard ask(Text.uiLeaveList.text + "\n\n" + Text.uiLeaveOneClick.text(["target": target]),
                      title: Text.uiUnsubscribe.text, style: .information) else { return }
            unsubscribeRequest = pe_unsubscribe(core.handle, folder, uid)
            status(unsubscribeRequest != 0 ? Text.macUnsubscribing.text(["target": target]) : Text.uiCannotUnsubscribe.text)
        case PE_UNSUBSCRIBE_MAIL:
            if ask(Text.uiLeaveList.text + "\n\n" + Text.uiLeaveMail.text(["target": target]),
                   title: Text.uiUnsubscribe.text, yes: Text.uiOk.text, no: Text.uiCancel.text, style: .information) {
                openMailto(link)
            }
        case PE_UNSUBSCRIBE_WEB:
            if ask(Text.uiLeaveList.text + "\n\n" + Text.uiLeaveWeb.text(["target": target]),
                   title: Text.uiUnsubscribe.text, yes: Text.uiOk.text, no: Text.uiCancel.text, style: .information) {
                openExternally(URL(string: link))
            }
        default:
            break
        }
    }

    /// the answer to a one-click unsubscribe this reader asked for, in words; nil for another's
    func unsubscribed(_ request: UInt64, problem: String) -> String? {
        guard request != 0, request == unsubscribeRequest else { return nil }
        unsubscribeRequest = 0
        return problem.isEmpty ? Text.uiUnsubscribed.text : Text.uiNotUnsubscribed.text(["reason": problem])
    }

}

// the attachment menu is made when it opens, from the message view
extension Reader: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === attachments.menu else { return }
        let title = menu.items.first?.copy() as? NSMenuItem
        menu.removeAllItems()
        if let title {
            menu.addItem(title)
        }
        for item in attachmentMenu().items {
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
    private var row: NSStackView?

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
        words.detachesHiddenViews = true
        // as tall as its lines, in the middle of the bar beside taller buttons
        words.setHuggingPriority(.required, for: .vertical)
        var views: [NSView] = [image, words]
        // takes what is left: a button goes to the trailing edge, a link right after the words
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        spacer.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        if let action {
            action.target = self
            action.action = #selector(fire)
            action.setContentHuggingPriority(.required, for: .horizontal)
            action.setContentCompressionResistancePriority(.required, for: .horizontal)
            // a long text gives way in its middle, never under the link
            textLabel.lineBreakMode = .byTruncatingMiddle
            views += button != nil ? [spacer, action] : [action, spacer]
        }
        let stack = NSStackView(views: views)
        row = stack
        stack.distribution = .fill
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

    /// controls at the trailing edge of a bar without a link or button of its own (the rest of it is still clicked as
    /// a whole)
    func setAccessories(_ views: [NSView]) {
        guard let row, action == nil else { return }
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        spacer.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        row.addArrangedSubview(spacer)
        for view in views {
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            row.addArrangedSubview(view)
        }
    }

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

/// The find bar of a message, as Safari and Mail have it: the words, the place before and after, Done. Return and
/// Cmd+G find the next place, Shift with them the one before, Esc closes it; it says when the words are not there.
@MainActor
final class FindBar: NSView, NSSearchFieldDelegate {
    /// looks for the words after (or before, `backwards`) the place found last, and says whether they are there
    var find: (String, Bool, @escaping (Bool) -> Void) -> Void = { _, _, _ in }
    /// the bar closed: the message takes the keyboard back
    var closed: () -> Void = {}
    let field = NSSearchField()
    private let steps = NSSegmentedControl()
    private let note = NSTextField(labelWithString: "")
    private var typingTimer: Timer?

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        isHidden = true
        setAccessibilityIdentifier("find.bar")
        field.placeholderString = Text.uiFindInMessageHint.text
        field.delegate = self
        field.sendsSearchStringImmediately = false
        field.sendsWholeSearchString = true
        field.setAccessibilityIdentifier("find.words")
        field.widthAnchor.constraint(equalToConstant: 240).isActive = true
        field.controlSize = .small
        field.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        steps.segmentCount = 2
        steps.trackingMode = .momentary
        steps.controlSize = .small
        steps.setImage(Icons.list("arrow_up"), forSegment: 0)
        steps.setImage(Icons.list("arrow_down"), forSegment: 1)
        steps.setToolTip(Text.uiTbPrevious.text, forSegment: 0)
        steps.setToolTip(Text.uiTbNext.text, forSegment: 1)
        steps.target = self
        steps.action = #selector(stepped)
        steps.setAccessibilityIdentifier("find.steps")
        note.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        note.textColor = .systemRed
        note.lineBreakMode = .byTruncatingTail
        note.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        note.setAccessibilityIdentifier("find.note")
        let done = NSButton(title: Text.uiDone.text, target: self, action: #selector(close))
        done.controlSize = .small
        done.bezelStyle = .push
        done.setAccessibilityIdentifier("find.done")
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let row = NSStackView(views: [field, steps, note, spacer, done])
        row.spacing = 8
        row.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        let line = NSBox()
        line.boxType = .separator
        let stack = NSStackView(views: [row, line])
        stack.orientation = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.widthAnchor.constraint(equalTo: stack.widthAnchor),
            line.widthAnchor.constraint(equalTo: stack.widthAnchor),
            row.heightAnchor.constraint(equalTo: stack.heightAnchor, constant: -1),
        ])
        updateSteps()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    /// shown, the words selected to type over
    func open() {
        isHidden = false
        window?.makeFirstResponder(field)
        field.currentEditor()?.selectAll(nil)
    }

    @objc func close() {
        typingTimer?.invalidate()
        isHidden = true
        note.stringValue = ""
        closed()
    }

    /// the place after the one found last (`backwards`: before it)
    func next(backwards: Bool = false) {
        typingTimer?.invalidate()
        let words = field.stringValue.trimmingCharacters(in: .whitespaces)
        guard !words.isEmpty else {
            note.stringValue = ""
            return
        }
        find(words, backwards) { [weak self] found in
            self?.note.stringValue = found ? "" : Text.uiFindNotFound.text(["words": words])
        }
    }

    private func updateSteps() {
        let some = !field.stringValue.trimmingCharacters(in: .whitespaces).isEmpty
        steps.setEnabled(some, forSegment: 0)
        steps.setEnabled(some, forSegment: 1)
    }

    @objc private func stepped() {
        next(backwards: steps.selectedSegment == 0)
    }

    // the words looked for as they are typed, a moment after the last key
    func controlTextDidChange(_ notification: Notification) {
        updateSteps()
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.next() }
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            next(backwards: NSApp.currentEvent?.modifierFlags.contains(.shift) == true)
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            close()
            return true
        default:
            return false
        }
    }

    // Cmd+G and Shift+Cmd+G while the bar is open, wherever the keyboard is in the window; Esc closes it first
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard !isHidden else { return super.performKeyEquivalent(with: event) }
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        if event.charactersIgnoringModifiers?.lowercased() == "g" && (modifiers == .command || modifiers == [.command, .shift]) {
            next(backwards: modifiers.contains(.shift))
            return true
        }
        if event.keyCode == 53 && modifiers.isEmpty {
            close()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// The header of the message shown: its text can be selected with the mouse, but Tab passes it by, as it would only
/// select all of it on the way from the list to the message
final class HeaderText: NSTextField {
    override var canBecomeKeyView: Bool { false }
}
