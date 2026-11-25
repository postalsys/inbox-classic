// The reading pane: the header of the message (From, Date, To, Cc, Subject) with the brand's logo at its left and the
// attachments and Unsubscribe at its right; under it the strip of its files to open (Attachments.swift), the security bar of a signed or encrypted message
// (SecurityBar.swift) and the bar that offers the pictures from the internet; then the
// message itself, with the cards of the core above it (a calendar event, a bounce, a one-time code). Every string shown is the core's, decoded and checked there.
// It asks the core for the message it shows and hears its events, so the main window's pane and a message's own window
// (MessageWindow.swift) are each one of these.
import AppKit
import CInboxClassic
import WebKit

@MainActor
final class Reader: NSObject {
    let view = ReaderStack()
    let core: Core
    /// what it has to say in the main window's status bar (leaving a mailing list)
    var status: (String) -> Void = { _ in }
    /// a message to write (leaving a mailing list by mail), from the account of the message it is about
    var openDraft: (_ draft: Draft, _ account: Int64) -> Void = { _, _ in }
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
    /// the file of the strip being opened, one at a time
    private var opening: Int?
    /// the size of the message asked for, from the list, for the page shown while it is downloaded
    private var loadingSize: UInt64 = 0
    /// its pictures from the internet were asked for
    private(set) var remoteImages = false
    /// a download asked for and not answered yet: MessageReady or MessageFailed for it is this reader's
    private var waiting = false
    /// the next message opened is shown in its conversation (Show the whole conversation), not alone
    var inConversation = false
    private var viewRequest: UInt64 = 0
    private var logoRequest: UInt64 = 0
    /// without a logo, the sender's picture from the Address Book drawn for the logo's place
    private var pictureRequest: UInt64 = 0
    private var unsubscribeRequest: UInt64 = 0
    /// Find Key on the label of a part signed by a key not known here: its lookup, 0 for none
    private var findRequest: UInt64 = 0
    /// the printout with the pictures being made (`pe_print_start`), and what says so meanwhile
    private var printRequest: UInt64 = 0
    private var printIdle: () -> Void = {}
    /// the next document shown is the same message made again: shown where the one before was scrolled to
    private var keepScroll = false
    /// the view shown is a large message's text, the rest still downloading
    private var textFirst = false
    private let preview = Preview()
    /// Find in This Message: a bar over the message, as Safari and Mail have
    private let findBar = FindBar()
    private let header = HeaderText(wrappingLabelWithString: "")
    /// under the header fields: "Reactions:" and a chip a person who reacted, shown only when someone did
    private let reactionsRow = NSStackView()
    private let reactionsLabel = NSTextField(labelWithString: "")
    /// the core's list the chips stand for, kept while they are shown (their menus act on it)
    private var reactions: OpaquePointer?
    private let logo = NSImageView()
    /// the header and the line under it, shown only over a message
    private let headerBox = NSView()
    private let headerLine = NSBox()
    private let attachments = NSPopUpButton(frame: .zero, pullsDown: true)
    /// the files under the header, to open
    let strip = AttachmentStrip()
    /// over a signed or encrypted message: its state, and Details
    let security = SecurityBar()
    private let pictures = InfoBar(icon: "image")
    /// the bar's Download Pictures with its menu: the Always choices for a sender the provider confirmed, the
    /// greyed line that says why there are none for one it did not
    let picturesChoices = NSComboButton()
    /// the bar's Download Pictures alone, for a message without a single sender
    let picturesDownload = NSButton()
    /// over a message that could not be downloaded: Try Again
    private let retry = InfoBar(icon: "arrow_sync", button: Text.uiTryAgain.text)
    /// over a message of a mailing list: the core's words (the list's domain, or when it was asked) and its button,
    /// which leaves the list as Message > Unsubscribe from List does
    private let listBar = InfoBar(icon: "mail_multiple", button: Text.uiUnsubscribeAsk.text)
    /// a moment after a message is asked for, the pane says it is being downloaded (one that is cached shows first)
    private var downloadingTimer: Timer?
    private(set) var picturesOffered = false
    /// over several messages: the numbers the core's page shows
    private var summary: PeSelectionSummary?
    /// the logo's side in pixels, for the core to draw it at
    var logoPixels: Int { Int(48 * (view.window?.backingScaleFactor ?? 2)) }

    deinit {
        pe_reactions_free(reactions)
    }

    init(core: Core) {
        self.core = core
        super.init()
        preview.core = core
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

        let right = NSStackView(views: [attachments])
        right.orientation = .vertical
        right.alignment = .trailing
        right.setContentHuggingPriority(.required, for: .horizontal)
        setUpReactions()
        // the header fields, the reactions under them
        let fields = NSStackView(views: [header, reactionsRow])
        fields.orientation = .vertical
        fields.alignment = .leading
        // as far under Subject as the header's lines are apart
        fields.spacing = 3
        fields.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        fields.setContentHuggingPriority(.init(249), for: .horizontal)
        header.widthAnchor.constraint(equalTo: fields.widthAnchor).isActive = true
        reactionsRow.widthAnchor.constraint(lessThanOrEqualTo: fields.widthAnchor).isActive = true
        let top = NSStackView(views: [logo, fields, right])
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
            fields.bottomAnchor.constraint(lessThanOrEqualTo: headerBox.bottomAnchor, constant: -8),
            logo.bottomAnchor.constraint(lessThanOrEqualTo: headerBox.bottomAnchor, constant: -8),
        ])
        headerLine.boxType = .separator

        pictures.text = Text.uiPicturesBlocked.text
        pictures.setAccessibilityIdentifier("reader.pictures")
        setUpPicturesButtons()
        retry.text = taken(pe_retry_note()) ?? ""
        retry.clicked = { [weak self] in self?.retryDownload() }
        retry.setAccessibilityIdentifier("reader.retry")
        retry.isHidden = true
        listBar.clicked = { [weak self] in self?.unsubscribeList() }
        listBar.setAccessibilityIdentifier("reader.list")
        listBar.isHidden = true
        // the size of the pictures bar's buttons, so stacked bars line up
        listBar.smallButton()
        // the links of the document's own cards: the core says which link it is, the view has what it needs
        preview.links = { [weak self] link in self?.followLink(link) ?? false }
        pictures.isHidden = true
        security.details = { [weak self] in self?.showSecurityDetails() }
        strip.opened = { [weak self] index in self?.openAttachment(index) }
        strip.menuOf = { [weak self] index in self?.fileMenu(index) ?? NSMenu() }
        view.security = security

        view.orientation = .vertical
        view.spacing = 0
        view.alignment = .leading
        findBar.find = { [weak self] words, backwards, done in self?.find(words, backwards: backwards, done: done) }
        findBar.closed = { [weak self] in
            guard let self else { return }
            view.window?.makeFirstResponder(preview.view)
        }
        // the bars in one order: the download that failed, the pictures, the mailing list
        for part in [headerBox, strip, headerLine, security, retry, pictures, listBar, findBar, preview.view] as [NSView] {
            view.addArrangedSubview(part)
            part.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        }
        view.setHuggingPriority(.defaultLow, for: .vertical)
        preview.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        pictures.heightAnchor.constraint(equalToConstant: 28).isActive = true
        retry.heightAnchor.constraint(equalToConstant: 34).isActive = true
        listBar.heightAnchor.constraint(equalToConstant: 28).isActive = true
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
        showReactions(nil)
        // no empty band over the pane's "no message" or several messages' page; a message about to load keeps it
        showHeader(loading)
        // the files of the message before are never offered for the next one
        strip.clear()
        // the bars of the message before stay while the next one loads, and go when it is there without them
        if !loading {
            attachments.isHidden = true
            pictures.isHidden = true
            picturesOffered = false
            listBar.isHidden = true
        }
        // never the bar of the message before over the next one
        security.hide()
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
        downloadingTimer = Timer.scheduledTimer(withTimeInterval: Mailbox.loadingWait, repeats: false) { [weak self] _ in
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
        strip.clear()
        pictures.isHidden = true
        picturesOffered = false
        listBar.isHidden = true
        security.hide()
        retry.isHidden = false
        preview.showState(PE_READER_STATE_FAILED, failure: kind, reason: reason)
    }

    var showsFailure: Bool { !retry.isHidden }

    func showProblem(_ problem: String) {
        downloadingTimer?.invalidate()
        showHeader(true)
        header.stringValue = problem
        security.hide()
        attachments.isHidden = true
        strip.clear()
        pictures.isHidden = true
        picturesOffered = false
        listBar.isHidden = true
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
        strip.show(view.attachments)
        // a message of a folder: who reacted to it (a file has none)
        loadReactions()
        // a mailing list that says how to leave it: the core's bar (none for a message file)
        showListBar(text: text(info.list_bar), button: text(info.list_button))
        // asked for, or loaded by themselves (Settings, a trusted sender the provider confirmed): the core says
        let allowed = info.pictures_loaded || remoteImages
        security.show(info)
        // the parts of a signed or encrypted message are documents of their own, in frames the app sizes to them
        let parts = info.part_count > 0 ? { [view] (index: Int) in view.part(index) } : nil
        preview.show(text(info.document), pictures: allowed, parts: parts, previews: text(info.preview_token),
                     keepScroll: keepScroll)
        keepScroll = false
        // a large message's text before the rest of it: made again when the rest is here
        textFirst = file == nil && pe_message_downloading(core.handle, folder, uid)
        // offered only for a message with pictures on the internet, until they are shown
        picturesOffered = info.remote_images && !allowed
        pictures.isHidden = !picturesOffered
        if picturesOffered {
            offerPictures(info)
        }
    }

    // ---- the pictures bar ----

    /// Download Pictures on the bar, as a click does: the combo button beside the sender's choices, or the button
    /// alone (the UI test)
    func pressDownloadPictures() {
        let download: NSControl = picturesChoices.isHidden ? picturesDownload : picturesChoices
        download.sendAction(download.action, to: download.target)
    }

    private func setUpPicturesButtons() {
        let label = Command.pictures.label
        picturesChoices.title = label
        picturesChoices.style = .split
        picturesChoices.makeSmall()
        picturesChoices.target = self
        picturesChoices.action = #selector(downloadClicked)
        picturesChoices.menu = NSMenu()
        picturesChoices.setAccessibilityIdentifier("reader.pictures.choices")
        picturesDownload.title = label
        picturesDownload.bezelStyle = .push
        picturesDownload.makeSmall()
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

    // ---- the reactions ----

    private func setUpReactions() {
        reactionsLabel.stringValue = Text.uiReactionsLabel.text
        reactionsLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        reactionsLabel.textColor = .secondaryLabelColor
        reactionsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        reactionsRow.orientation = .horizontal
        reactionsRow.alignment = .centerY
        reactionsRow.spacing = 6
        reactionsRow.addView(reactionsLabel, in: .leading)
        reactionsRow.setVisibilityPriority(.mustHold, for: reactionsLabel)
        reactionsRow.setCustomSpacing(8, after: reactionsLabel)
        reactionsRow.setAccessibilityIdentifier("reader.reactions")
        reactionsRow.setAccessibilityElement(true)
        reactionsRow.setAccessibilityRole(.group)
        reactionsRow.setAccessibilityLabel(Text.uiReactionsLabel.text)
        reactionsRow.isHidden = true
    }

    /// the reactions to the message shown read again from the core: when it is shown, and when its folder changed
    /// (a reaction came, or one was shown as an email)
    private func loadReactions() {
        guard file == nil, uid != 0 else {
            showReactions(nil)
            return
        }
        showReactions(pe_reactions(core.handle, folder, uid))
    }

    /// a chip a person of `list` (taken, freed when replaced), the row hidden without any
    private func showReactions(_ list: OpaquePointer?) {
        for chip in reactionsRow.views where chip !== reactionsLabel {
            reactionsRow.removeView(chip)
        }
        pe_reactions_free(reactions)
        reactions = list
        let count = pe_reactions_count(list)
        for index in 0..<count {
            guard let reaction = pe_reactions_get(list, index)?.pointee else { continue }
            let chip = ReactionChip(text: text(reaction.text), when: text(reaction.when), index: index)
            chip.menu = reactionMenu(chip)
            chip.target = self
            chip.action = #selector(chipClicked(_:))
            reactionsRow.addView(chip, in: .leading)
            // what does not fit is left out rather than squeezed
            reactionsRow.setVisibilityPriority(.detachOnlyIfNecessary, for: chip)
        }
        reactionsRow.isHidden = count == 0
    }

    /// the chips' words, "👍 Kate Kalda" (for the UI test)
    var reactionChips: [String] { reactionsRow.isHidden ? [] : chips.map(\.title) }

    /// the menu of the chip `index` (for the UI test)
    func reactionMenu(at index: Int) -> NSMenu? { chips.first { $0.index == index }?.menu }

    private var chips: [ReactionChip] { reactionsRow.views.compactMap { $0 as? ReactionChip } }

    /// a chip's menu: the email opened, the email listed again, and when the reaction came
    private func reactionMenu(_ chip: ReactionChip) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let open = menu.addItem(withTitle: Text.uiReactionOpenEmail.text, action: #selector(openReactionChosen(_:)), keyEquivalent: "")
        let show = menu.addItem(withTitle: Text.uiReactionShowAsEmail.text, action: #selector(showAsEmailChosen(_:)), keyEquivalent: "")
        for item in [open, show] {
            item.target = self
            item.tag = chip.index
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: Text.uiReactionWhen.text(["when": chip.when]), action: nil, keyEquivalent: "").isEnabled = false
        return menu
    }

    /// a click on a chip opens its menu under it, as a pop-up button's does
    @objc private func chipClicked(_ chip: ReactionChip) {
        chip.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: chip.bounds.height + 4), in: chip)
    }

    @objc private func openReactionChosen(_ sender: NSMenuItem) {
        openReactionEmail(sender.tag)
    }

    /// Open Reaction Email: the email written to a file the core keeps, opened in a message window as a message file
    /// from the Finder is
    func openReactionEmail(_ index: Int) {
        guard let reactions, let path = taken(pe_reactions_email_file(core.handle, reactions, index)) else {
            inform(Text.uiNotShown.text, style: .warning, in: view.window)
            return
        }
        AppDelegate.shared?.application(NSApp, open: [URL(fileURLWithPath: path)])
    }

    @objc private func showAsEmailChosen(_ sender: NSMenuItem) {
        showReactionAsEmail(sender.tag)
    }

    /// Show as Email: the person's emails listed again for good, their chip gone
    func showReactionAsEmail(_ index: Int) {
        guard let reactions else { return }
        pe_reactions_show_as_email(core.handle, reactions, index)
        loadReactions()
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

    /// the brand's logo as it is, or a person's picture `round` as the list shows it
    func showLogo(_ pixels: Data?, round: Bool = false) {
        guard let image = pixelImage(pixels, side: logoPixels, points: 48) else { return }
        logo.image = round ? roundImage(image) : image
        logo.isHidden = false
    }

    /// the mailing list's bar as the core words it; no words, no bar
    private func showListBar(text words: String, button: String) {
        listBar.text = words
        listBar.buttonTitle = button
        listBar.isHidden = words.isEmpty
    }

    /// the core's ListsChanged: a list was asked to let the user go, or a request failed, so the bar is read again
    func listsChanged() {
        guard file == nil, uid != 0, messageView?.info?.pointee.unsubscribe ?? PE_UNSUBSCRIBE_NONE != PE_UNSUBSCRIBE_NONE
        else { return }
        let bar = pe_list_bar(core.handle, folder, uid)
        defer { pe_list_bar_free(bar) }
        showListBar(text: text(bar.text), button: text(bar.button))
    }

    /// Message > Unsubscribe from List: on while the bar offers its button
    var canUnsubscribe: Bool { !listBar.isHidden && !listBar.buttonTitle.isEmpty }

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
        keepScroll = false
        textFirst = false
        endPrint()
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

    /// the same message made again, shown where it was scrolled to: Show in Message chosen, or the whole of a large
    /// message here after its text
    func rebuild() {
        keepScroll = true
        reload()
    }

    /// the whole of a large message whose text is shown is here: its view made again, the tiles that said its files
    /// were on their way now the previews
    private func wholeMessageHere() {
        guard textFirst, file == nil, !waiting, !pe_message_downloading(core.handle, folder, uid) else { return }
        textFirst = false
        rebuild()
    }

    /// the message shown made again: Settings' pictures or trusted senders changed
    func reload() {
        guard showsMessage else { return }
        if file != nil {
            _ = showFile()
        } else {
            makeView()
        }
    }

    /// a view asked for and not here yet
    var waitingForView: Bool { viewRequest != 0 }

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

    /// parsing, folding and sanitizing a large message takes a while: on a worker, ViewReady follows; in its
    /// conversation, the conversation's view
    private func makeView() {
        if viewRequest != 0 {
            pe_message_view_cancel(core.handle, viewRequest)
        }
        viewRequest = inConversation
            ? pe_conversation_view_start(core.handle, folder, uid, remoteImages, AppDelegate.shared.conversationNewestFirst)
            : pe_message_view_start(core.handle, folder, uid, remoteImages)
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
            } else if event.folder == folder && event.uid == uid {
                wholeMessageHere()
            } else if let messageView, pe_message_view_waits_for(messageView.handle, event.folder, event.uid) {
                // an open message of the conversation shown is downloaded: the conversation made again, where it was
                rebuild()
            }
        case PE_EVENT_KIND_TRANSFERRING:
            // how far a large message is, then that it is all here (stored by then)
            wholeMessageHere()
        case PE_EVENT_KIND_PRINT_READY:
            if printRequest != 0 && event.uid == printRequest {
                printReady()
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
        case PE_EVENT_KIND_PREVIEWS_PREPARED:
            // the files of the view shown that were "Preparing..." are described: the view made again where it was
            // scrolled to; another window's view is not this one
            if showsPrepared(event.detail) {
                rebuild()
            }
        case PE_EVENT_KIND_KEYS_FOUND:
            // Find Key's lookup: the keys found taken in, what was found said, and the message made again, its label
            // now naming who signed it
            if findRequest != 0 && event.uid == findRequest {
                findRequest = 0
                if let said = core.pgpFindResult(event.uid) {
                    status(said)
                }
                rebuild()
            }
        case PE_EVENT_KIND_FOLDER_CHANGED:
            // a reaction to the message shown came, or one was listed as an email again
            if event.folder == folder && showsMessage {
                loadReactions()
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

    /// whether the view shown is the one a PreviewsPrepared event's token names
    func showsPrepared(_ token: String) -> Bool {
        guard showsMessage, !token.isEmpty, let info = messageView?.info else { return false }
        return text(info.pointee.preview_token) == token
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
        case PE_READER_LINK_PART:
            // after the web view's question is answered: the window runs modally
            onMain { [weak self] in self?.showSecurityDetails() }
            return true
        case PE_READER_LINK_FIND_KEY:
            // the core reads the handle from the link and asks keys.openpgp.org by it; the page offers no Find Key
            // while lookups there are turned off
            guard showsMessage, findRequest == 0 else { return true }
            findRequest = core.pgpFindHandle(link)
            if findRequest != 0 {
                status(Text.pgpRecipientLooking.text)
            }
            return true
        case PE_READER_LINK_CONVERSATION:
            let index = pe_conversation_link_index(link)
            onMain { [weak self] in self?.conversationLine(index) }
            return true
        case PE_READER_LINK_CONVERSATION_EARLIER:
            onMain { [weak self] in
                guard let self, self.uid != 0 else { return }
                pe_conversation_show_earlier(self.core.handle, self.folder, self.uid)
                self.rebuild()
            }
            return true
        case PE_READER_LINK_ATTACHMENT:
            // a preview after the text: its file opened as a double-click in the strip opens it; only a link of the
            // message this reader shows (the core checks its view's token)
            let token = messageView?.info?.pointee.preview_token
            let index = link.withCString { pe_preview_link(core.handle, $0, token) }
            if index >= 0 {
                onMain { [weak self] in self?.openAttachment(Int(index)) }
            }
            return true
        default:
            return false
        }
    }

    /// the view shown is a conversation's
    var showsConversation: Bool { (messageView?.info?.pointee.conversation_count ?? 0) > 0 }

    /// a line of the conversation shown clicked: its message opens or folds, and the conversation is shown again
    /// where it was, at the message the core says has the focus (downloaded first when it is not yet)
    func conversationLine(_ index: Int64) {
        guard uid != 0 else { return }
        var to: (folder: Int64, uid: UInt64) = (0, 0)
        guard pe_conversation_click(core.handle, folder, uid, index, &to.folder, &to.uid) else { return }
        if to.folder == folder && to.uid == uid {
            rebuild()
            return
        }
        folder = to.folder
        uid = to.uid
        keepScroll = true
        waiting = true
        pe_message_open(core.handle, folder, uid)
    }

    /// File > Print Conversation: every message of the conversation shown; the message alone outside one
    func printConversation() {
        guard showsMessage, uid != 0, printRequest == 0 else { return }
        // made off the window thread, PrintReady says it is; outside a conversation, the message alone
        let request = pe_conversation_print_start(core.handle, folder, uid, AppDelegate.shared.conversationNewestFirst)
        guard request != 0 else {
            print()
            return
        }
        printRequest = request
        printIdle = Pending.busy(status)
    }

    /// Security Details: the core's words of every part of the message shown
    func showSecurityDetails() {
        guard let info = messageView?.info?.pointee, info.protection != PE_PROTECTION_TONE_NONE else { return }
        SecurityDetails.run(text(info.protection_details), owner: view.window)
    }

    /// what the app's own script `script` says of the message's page, for the UI test
    func pageAnswer(_ script: String) async -> String {
        await preview.pageAnswer(script)
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

    /// a reply, a reply to all or a forward of the message shown, made off the window thread (the message parsed and
    /// decrypted there), then `done` with it (nil when there is no message); of a message file from `account`, at once
    func startDraft(_ kind: PeDraftKind, account from: Int64 = 0, _ done: @escaping (Draft?) -> Void) {
        guard showsMessage else { return done(nil) }
        if let file {
            return done(file.withCString { Draft(pe_file_draft(core.handle, $0, from, kind)) })
        }
        let request = pe_message_draft_start(core.handle, folder, uid, kind)
        let idle = Pending.busy(status)
        guard Pending.read(request, by: self, { [core] in
            idle()
            done(Draft(pe_draft_result(core.handle, request)))
        }) else {
            idle()
            return done(nil)
        }
    }

    /// the reads the reader waits for dropped: its window closed
    func cancelReads() {
        Pending.cancel(by: self, core: core)
    }

    /// the message as it is shown, with the pictures it shows
    func print() {
        guard showsMessage, let info = messageView?.info, printRequest == 0 else { return }
        // a message with pictures or PDF files after its text: the core draws them if it has not, off the window
        // thread, and PrintReady says the printout is made
        let token = text(info.pointee.preview_token)
        if !token.isEmpty {
            printRequest = token.withCString { pe_print_start(core.handle, $0) }
            if printRequest != 0 {
                printIdle = Pending.busy(status)
                return
            }
        }
        printDocument(text(info.pointee.print_document))
    }

    /// the printout of the core's PrintReady: the message with its pictures, or as it is should the printout be gone
    private func printReady() {
        let request = printRequest
        endPrint()
        guard let info = messageView?.info else { return }
        printDocument(taken(pe_print_result(core.handle, request)) ?? text(info.pointee.print_document))
    }

    private func endPrint() {
        printRequest = 0
        printIdle()
        printIdle = {}
    }

    /// the core's printout: for a protected message one document of every part's text, as no frame prints
    private func printDocument(_ document: String) {
        guard let info = messageView?.info else { return }
        TestHooks.printDocument?(document)
        Printer.print(document, pictures: info.pointee.pictures_loaded || remoteImages,
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
        saveAttachment(at: sender.tag)
    }

    /// Save As of a file: read from the message file shown at once, from the store off the window thread (a large
    /// message parsed and decrypted there), then the panel to save it with
    private func saveAttachment(at index: Int) {
        if let file {
            var length = 0
            var name: UnsafeMutablePointer<CChar>?
            let bytes = file.withCString { pe_file_attachment_data(core.handle, $0, index, &length, &name) }
            return saveAttachment(takenBytes(bytes, length), named: taken(name))
        }
        let request = pe_attachment_data_start(core.handle, folder, uid, index)
        let idle = Pending.busy(status)
        guard Pending.read(request, by: self, { [weak self] in
            idle()
            guard let self else { return }
            var length = 0
            var name: UnsafeMutablePointer<CChar>?
            let bytes = pe_attachment_data_result(core.handle, request, &length, &name)
            saveAttachment(takenBytes(bytes, length), named: taken(name))
        }) else {
            idle()
            return notHere()
        }
    }

    private func saveAttachment(_ data: Data?, named name: String?) {
        guard let data else {
            notHere()
            return
        }
        if let url = saveFilePanel(name: name ?? "attachment"), !writeDownloaded(data, to: url) {
            inform(Text.uiAttachmentNotSaved.text, style: .error)
        }
    }

    /// a file of the message could not be read: a large message shows its text before the rest of it is here
    private func notHere() {
        if file == nil && pe_message_downloading(core.handle, folder, uid) {
            inform(Text.uiAttachmentDownloading.text)
        } else {
            inform(Text.uiAttachmentNotRead.text, style: .error)
        }
    }

    /// attachment `index` opened with the program the system has for it: refused from its row, in the core's words,
    /// for a file that can run programs; else the core writes it into a private folder of the user's on a background
    /// thread (reading and decrypting a large message takes a while; its tile shows it is busy after a moment), with an
    /// encrypted message's note to show first (once). The file is marked as from the internet, as a download is.
    func openAttachment(_ index: Int) {
        guard showsMessage, let attachment = messageView?.attachment(index) else { return }
        guard attachment.canOpen else {
            inform(attachment.refusal, style: .warning)
            return
        }
        guard opening == nil else { return }
        opening = index
        let busy = after(Mailbox.loadingWait) { [weak self] in self?.strip.busy(index) }
        let handle = core.handle
        let (file, folder, uid) = (file, folder, uid)
        guard let file else {
            // a message of the store: written off the window thread by the core
            let request = pe_attachment_open_start(handle, folder, uid, index)
            let waits = Pending.read(request, by: self) { [weak self] in
                busy.invalidate()
                var note: UnsafeMutablePointer<CChar>?
                var error: UnsafeMutablePointer<CChar>?
                let written = taken(pe_attachment_open_result(handle, request, &note, &error))
                self?.opened(path: written, note: taken(note), refused: taken(error))
            }
            if !waits {
                busy.invalidate()
                opened(path: nil, note: nil, refused: nil)
            }
            return
        }
        inBackground({
            var note: UnsafeMutablePointer<CChar>?
            var error: UnsafeMutablePointer<CChar>?
            let written = file.withCString { pe_file_attachment_open(handle, $0, index, &note, &error) }
            return (taken(written), taken(note), taken(error))
        }, then: { [weak self] (path, note, refused) in
            busy.invalidate()
            self?.opened(path: path, note: note, refused: refused)
        })
    }

    /// what the core gave for the file being opened: the file, shown after its note; or why there is none
    private func opened(path: String?, note: String?, refused: String?) {
        opening = nil
        strip.busy(nil)
        if let refused {
            inform(refused, style: .warning)
            return
        }
        guard let path else {
            notHere()
            return
        }
        if let note {
            inform(Text.uiAttachmentNoteTitle.text + "\n\n" + note)
        }
        let url = URL(fileURLWithPath: path)
        markFromInternet(url)
        if let test = TestHooks.openFile {
            test(url)
            return
        }
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, failed in
            guard let failed else { return }
            onMain { inform(failed.localizedDescription, style: .warning) }
        }
    }

    /// the menu of a file of the strip: Open (off for a file that can run programs), Save As, Save All
    func fileMenu(_ index: Int) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        guard let attachment = messageView?.attachment(index) else { return menu }
        let open = menu.addItem(withTitle: Text.uiAttachmentOpen.text, action: #selector(openChosen(_:)), keyEquivalent: "")
        open.isEnabled = attachment.canOpen
        if !attachment.canOpen {
            open.toolTip = attachment.tooltip
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: Text.uiAttachmentSaveAs.opens, action: #selector(saveAttachment(_:)), keyEquivalent: "")
        menu.addItem(withTitle: Text.uiAttachmentSaveAll.opens, action: #selector(saveAllAttachments), keyEquivalent: "")
        // a file that holds a public key: imported into Encryption Keys
        if attachment.isKey {
            menu.addItem(.separator())
            let importKey = menu.addItem(withTitle: Text.uiAttachmentImportKey.opens, action: #selector(importKeyChosen(_:)),
                                         keyEquivalent: "")
            importKey.identifier = NSUserInterfaceItemIdentifier("attachment.importKey")
        }
        // a picture or PDF file: drawn after the text (checked), not drawn (unchecked), or one that can not be (greyed)
        let state = messageView?.showInMessage(index) ?? PE_SHOW_IN_MESSAGE_NONE
        if state != PE_SHOW_IN_MESSAGE_NONE {
            menu.addItem(.separator())
            let show = menu.addItem(withTitle: Text.uiAttachmentShowInMessage.text, action: #selector(showInMessageChosen(_:)),
                                    keyEquivalent: "")
            show.state = state == PE_SHOW_IN_MESSAGE_ON ? .on : .off
            show.isEnabled = state != PE_SHOW_IN_MESSAGE_UNAVAILABLE
            show.identifier = NSUserInterfaceItemIdentifier("attachment.showInMessage")
        }
        for item in menu.items where !item.isSeparatorItem {
            item.target = self
            item.tag = index
        }
        return menu
    }

    /// Show in Message: the file drawn after the text, or taken out of it; the message made again where it was
    /// scrolled to
    @objc private func showInMessageChosen(_ sender: NSMenuItem) {
        showInMessage(sender.tag)
    }

    func showInMessage(_ index: Int) {
        guard showsMessage, let view = messageView, let info = view.info else { return }
        let token = text(info.pointee.preview_token)
        let state = view.showInMessage(index)
        guard !token.isEmpty, state == PE_SHOW_IN_MESSAGE_ON || state == PE_SHOW_IN_MESSAGE_OFF else { return }
        if token.withCString({ pe_preview_show(core.handle, $0, index, state != PE_SHOW_IN_MESSAGE_ON) }) {
            rebuild()
        }
    }

    @objc private func importKeyChosen(_ sender: NSMenuItem) {
        importKey(sender.tag)
    }

    /// Import Key of a file that holds a public key: the core reads (and decrypts) the message off the window thread and
    /// imports the file as a key file is, public keys only; then what it took in, and the messages shown made again
    func importKey(_ index: Int) {
        guard showsMessage, messageView?.attachment(index)?.isKey == true else { return }
        let (core, file, folder, uid) = (core, file, folder, uid)
        let idle = Pending.busy(status)
        inBackground({
            core.pgpImportAttachment(folder: folder, uid: uid, file: file, index: index)
        }, then: { result in
            idle()
            let title = Text.uiKeysImportTitle.text
            guard result.outcome == PE_IMPORT_OUTCOME_IMPORTED else {
                inform(result.message, title: title, style: .warning)
                return
            }
            KeyActions.imported(core: core, result.message, title: title)
            // a message signed by that key names its signer now, and the Address Book marks its owner
            AppDelegate.shared?.main?.reloadMessagesShown()
            AddressBookWindow.refresh()
        })
    }

    @objc private func openChosen(_ sender: NSMenuItem) {
        openAttachment(sender.tag)
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
        // into a private folder of the user's, which the core cleans once a day old
        guard let dir = taken(pe_private_folder(core.handle, "invitations")) else {
            inform(Text.uiInvitationNotRead.text, style: .error)
            return
        }
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

    /// the bar's button and Message > Unsubscribe from List: what will happen, asked with the verb, then done; the core
    /// remembers the list for the bars (a message to write once it is sent, a page once it is opened)
    func unsubscribeList() {
        guard canUnsubscribe, let info = messageView?.info?.pointee else { return }
        let target = text(info.unsubscribe_target)
        let detail: String
        switch info.unsubscribe {
        case PE_UNSUBSCRIBE_ONE_CLICK: detail = Text.uiLeaveOneClick.text(["target": target])
        case PE_UNSUBSCRIBE_MAIL: detail = Text.uiLeaveMail.text(["target": target])
        case PE_UNSUBSCRIBE_WEB: detail = Text.uiLeaveWeb.text(["target": target])
        default: return
        }
        guard ask(Text.uiLeaveList.text + "\n\n" + detail, title: Text.uiUnsubscribe.text,
                  yes: Text.uiUnsubscribe.text, no: Text.uiCancel.text, style: .information) else { return }
        switch info.unsubscribe {
        case PE_UNSUBSCRIBE_ONE_CLICK:
            unsubscribeRequest = pe_unsubscribe(core.handle, folder, uid)
            status(unsubscribeRequest != 0 ? Text.macUnsubscribing.text(["target": target]) : Text.uiCannotUnsubscribe.text)
        case PE_UNSUBSCRIBE_MAIL:
            // from the account of the message, whatever the main window shows
            if let draft = Draft(pe_unsubscribe_draft(core.handle, folder, uid)) {
                openDraft(draft, account)
            } else {
                status(Text.uiCannotUnsubscribe.text)
            }
        default:
            openExternally(URL(string: text(info.unsubscribe_link)))
            pe_unsubscribe_opened(core.handle, folder, uid)
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

/// A bar in the colors of an information bar: an icon, a bold title and a line of text (or one line), with a push
/// button or a closing cross at its right, and controls of its own before it; never clicked as a whole or by a link,
/// so each action is a button a keyboard and a screen reader reach
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

    /// `button`: a push button at the trailing edge (`clicked`); `close`: a cross there, named so for a screen reader,
    /// that closes the bar (`clicked`); neither: the bar's controls are its accessories
    init(icon: String, button: String? = nil, close: String? = nil) {
        if let close {
            let cross = NSButton(image: Icons.list("dismiss") ?? NSImage(), target: nil, action: nil)
            cross.isBordered = false
            cross.toolTip = close
            cross.setAccessibilityLabel(close)
            action = cross
        } else if let button {
            action = NSButton(title: button, target: nil, action: nil)
            action?.bezelStyle = .push
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
        // takes what is left: the button goes to the trailing edge
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        spacer.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        if let action {
            action.target = self
            action.action = #selector(fire)
            action.setContentHuggingPriority(.required, for: .horizontal)
            action.setContentCompressionResistancePriority(.required, for: .horizontal)
            // a long text gives way in its middle, never under the button
            textLabel.lineBreakMode = .byTruncatingMiddle
            views += [spacer, action]
        }
        let stack = NSStackView(views: views)
        row = stack
        stack.distribution = .fill
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        // a hairline under the bar, so bars stacked in the same colour read as separate bars
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor),
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

    /// controls at the trailing edge of the bar, before its own button when it has one
    func setAccessories(_ views: [NSView]) {
        guard let row else { return }
        // a bar with a button has its spacer before it already
        if action == nil {
            let spacer = NSView()
            spacer.setContentHuggingPriority(.init(1), for: .horizontal)
            spacer.setContentCompressionResistancePriority(.init(1), for: .horizontal)
            row.addArrangedSubview(spacer)
        }
        for view in views {
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            if let action, let at = row.arrangedSubviews.firstIndex(of: action) {
                row.insertArrangedSubview(view, at: at)
            } else {
                row.addArrangedSubview(view)
            }
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

    @objc private func fire() {
        clicked()
    }

    /// the text on as many lines as it needs (up to four), the bar as tall as they are: a sentence that must be read
    /// whole (the core's why)
    func wrapText() {
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.usesSingleLineMode = false
        textLabel.cell?.wraps = true
        textLabel.cell?.truncatesLastVisibleLine = true
        textLabel.maximumNumberOfLines = 4
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        row?.alignment = .centerY
        row?.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    }

    /// a small button, as the pictures bar's, for a bar stacked with it
    func smallButton() {
        action?.makeSmall()
    }

    /// the button's words; empty hides it (a bar that only says something)
    var buttonTitle: String {
        get { action?.isHidden == false ? action?.title ?? "" : "" }
        set {
            action?.title = newValue
            action?.isHidden = newValue.isEmpty
        }
    }

    /// the bar's button or cross pressed, as a click does (the UI test)
    func press() {
        action?.performClick(nil)
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

/// The reading pane's stack: a screen reader reads the security bar first for the message, before its header
final class ReaderStack: NSStackView {
    weak var security: NSView?

    override func accessibilityChildren() -> [Any]? {
        guard let children = super.accessibilityChildren(), let security, !security.isHidden else {
            return super.accessibilityChildren()
        }
        let bar = children.filter { ($0 as AnyObject) === security }
        return bar + children.filter { ($0 as AnyObject) !== security }
    }
}

/// One person's reactions in the header, "👍 Kate Kalda": a small rounded token, as Mail's address tokens are, whose
/// click (or right-click) opens its menu. Drawn by itself: the inline bezel's own grey text reads as disabled.
final class ReactionChip: NSButton {
    let index: Int
    let when: String
    private static let font = NSFont.systemFont(ofSize: NSFont.systemFontSize - 1)
    private static let height: CGFloat = 20
    private static let padding: CGFloat = 8
    /// the title as drawn: centred in the token, cut short with an ellipsis
    private let drawnTitle: NSAttributedString

    init(text: String, when: String, index: Int) {
        self.index = index
        self.when = when
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.alignment = .center
        drawnTitle = NSAttributedString(string: text, attributes: [
            .font: ReactionChip.font, .foregroundColor: NSColor.labelColor, .paragraphStyle: style,
        ])
        super.init(frame: .zero)
        isBordered = false
        setButtonType(.momentaryChange)
        attributedTitle = NSAttributedString(string: text, attributes: [
            .font: ReactionChip.font, .foregroundColor: NSColor.labelColor,
        ])
        lineBreakMode = .byTruncatingTail
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.required, for: .horizontal)
        toolTip = Text.uiReactionWhen.text(["when": when])
        setAccessibilityLabel(text)
        setAccessibilityHelp(toolTip)
        setAccessibilityRole(.popUpButton)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        let size = attributedTitle.size()
        return NSSize(width: ceil(size.width) + 2 * ReactionChip.padding, height: ReactionChip.height)
    }

    private var shape: NSBezierPath {
        NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
    }

    override func draw(_ dirtyRect: NSRect) {
        // the fill of a token, darker while pressed; the system's colours, so dark mode has its own
        (isHighlighted ? NSColor.tertiaryLabelColor : NSColor.quaternaryLabelColor).setFill()
        shape.fill()
        let size = attributedTitle.size()
        let room = bounds.insetBy(dx: ReactionChip.padding, dy: 0)
        let line = NSRect(x: room.minX, y: (bounds.height - size.height) / 2, width: room.width, height: size.height)
        drawnTitle.draw(with: line, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
    }

    override var focusRingMaskBounds: NSRect { bounds }

    override func drawFocusRingMask() {
        shape.fill()
    }
}

/// The header of the message shown: its text can be selected with the mouse, but Tab passes it by, as it would only
/// select all of it on the way from the list to the message
final class HeaderText: NSTextField {
    override var canBecomeKeyView: Bool { false }
}

extension NSControl {
    /// the small size the bars' buttons share, and its font: a combo button keeps the regular font otherwise, so the
    /// buttons side by side would not match
    func makeSmall() {
        controlSize = .small
        font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
    }
}
