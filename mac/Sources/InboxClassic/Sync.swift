// Settings sync (Settings > Sync): the core's calls, the Set Up Sync sheet (where the vault is, then the passphrase
// that starts or joins it), the Computers and History sheets, and the core's two sync events: what the others wrote
// applied when the core has read it, what a sync brought shown. The core keeps the vault and says everything in
// words; these windows hand it what was chosen or typed, and the app's own preferences as an export does.
import AppKit
import CInboxClassic

/// Sync as the Sync pane shows it
struct SyncState {
    let on: Bool
    let busy: Bool
    /// where it syncs through and as what computer, empty while off
    let place: String
    /// how it went, empty while off
    let status: String
    let choice: PeSyncChoice
}

/// A computer of the vault
struct SyncComputer {
    let device: String
    let name: String
    let seen: String
    let this: Bool
}

/// An edit another computer made that one made here at the same time replaced
struct SyncEdit {
    let id: Int64
    let when: String
    let item: String
    let value: String
    let source: String
}

/// A place as Set Up Sync takes it: a folder, or a bucket with its secret
struct SyncPlace {
    var folder: String?
    var endpoint = ""
    var region = ""
    var bucket = ""
    var prefix = ""
    var accessKey = ""
    var secret = ""

    /// `body` with the place and the secret as the core takes them, the strings alive while it runs
    func withC<T>(_ body: (UnsafePointer<PeSyncPlace>, UnsafePointer<CChar>?) -> T) -> T {
        let strings = CStrings()
        defer { strings.wipe() }
        var place = PeSyncPlace(kind: folder != nil ? PE_SYNC_PLACE_KIND_FOLDER : PE_SYNC_PLACE_KIND_BUCKET,
                                path: folder.map { strings.add($0) }, endpoint: strings.optional(endpoint),
                                region: strings.optional(region), bucket: strings.optional(bucket),
                                prefix: strings.optional(prefix), access_key: strings.optional(accessKey))
        let secret = folder == nil ? strings.optional(self.secret) : nil
        return withUnsafePointer(to: &place) { body($0, secret) }
    }
}

/// The switches of what to sync, in the pane's order, with the flag of the choice each stands for
let syncFlags: [(setting: Setting, flag: WritableKeyPath<PeSyncChoice, Bool>)] = [
    (.syncAccounts, \.accounts), (.syncPasswords, \.passwords), (.syncSignIns, \.sign_ins),
    (.syncSignInApps, \.sign_in_apps), (.syncAppSecrets, \.app_secrets), (.syncContacts, \.contacts),
    (.syncKeys, \.keys), (.syncPrivateKeys, \.private_keys), (.syncRules, \.rules), (.syncTrusted, \.trusted),
    (.syncSettings, \.settings), (.syncPreferences, \.preferences),
]

extension Core {
    var syncState: SyncState {
        guard let handle = pe_settings_sync_state(self.handle) else {
            return SyncState(on: false, busy: false, place: "", status: "", choice: pe_sync_choice_default())
        }
        defer { pe_settings_sync_state_free(handle) }
        guard let state = pe_settings_sync_state_get(handle)?.pointee else {
            return SyncState(on: false, busy: false, place: "", status: "", choice: pe_sync_choice_default())
        }
        return SyncState(on: state.on, busy: state.busy, place: text(state.place), status: text(state.status),
                         choice: state.choice)
    }

    /// the computers read, nil while they are read
    var syncComputers: [SyncComputer]? {
        guard let list = pe_settings_sync_computers(handle) else { return nil }
        defer { pe_settings_sync_computers_free(list) }
        return (0..<pe_settings_sync_computers_count(list)).compactMap { pe_settings_sync_computers_get(list, $0)?.pointee }
            .map { SyncComputer(device: text($0.device), name: text($0.name), seen: text($0.seen), this: $0.this_) }
    }

    /// the edits that lost to a later one, newest first
    var syncHistory: [SyncEdit] {
        guard let list = pe_settings_sync_history(handle) else { return [] }
        defer { pe_settings_sync_history_free(list) }
        return (0..<pe_settings_sync_history_count(list)).compactMap { pe_settings_sync_history_get(list, $0)?.pointee }
            .map { SyncEdit(id: $0.id, when: text($0.when), item: text($0.item), value: text($0.value), source: text($0.source)) }
    }
}

// ---- the core's events ----

@MainActor
enum SyncEvents {
    /// `body` with the app's preferences now, as an export carries them
    static func withPrefs<T>(_ body: (OpaquePointer?) -> T) -> T {
        let prefs = pe_setup_export_new(0)
        defer { prefs.map(pe_setup_export_free) }
        for pref in SetupPrefs.current {
            _ = pe_setup_export_set_pref(prefs, pref.name, pref.value)
        }
        return body(prefs)
    }

    /// `SettingsSyncReady`: what the others wrote applied, this computer's changes sent, with the preferences now
    static func ready(_ core: Core) {
        withPrefs { pe_settings_sync_continue(core.handle, $0) }
    }

    /// `SettingsSyncChanged`: the windows of sync show it as it is, the preferences another computer changed are
    /// applied as an import applies them, and what the user should know is said in the status bar
    static func changed(_ core: Core, main: MainWindow) {
        SettingsWindow.current?.refreshSync()
        SyncComputersSheet.current?.reload()
        SyncSetupSheet.current?.probed()
        guard let news = pe_settings_sync_news(core.handle) else { return }
        defer { pe_settings_sync_news_free(news) }
        // the language never syncs, so nothing here asks to start again
        let prefs = (0..<pe_settings_sync_news_prefs_count(news)).compactMap { pe_settings_sync_news_pref(news, $0)?.pointee }
            .map { (name: text($0.name), value: text($0.value), restart: false) }
        if !prefs.isEmpty {
            SetupPrefs.apply(prefs)
        }
        let notice = text(pe_settings_sync_news_notice(news))
        if !notice.isEmpty {
            main.setStatus(notice)
        }
    }
}

// ---- the parts of the sheets ----

/// A heading at the top of a sheet, which has no title bar
@MainActor
private func sheetHeading(_ words: String) -> NSTextField {
    let heading = NSTextField(wrappingLabelWithString: words)
    heading.isSelectable = false
    heading.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
    return heading
}

/// Words in the secondary look, smaller
@MainActor
private func smallNote(_ words: String, width: CGFloat) -> NSTextField {
    let note = wrappingLabel(hyphensKept(words))
    note.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
    note.textColor = .secondaryLabelColor
    note.preferredMaxLayoutWidth = width
    note.widthAnchor.constraint(equalToConstant: width).isActive = true
    return note
}

/// Why something was refused, in red
@MainActor
private func problemLabel(id: String) -> NSTextField {
    let problem = wrappingLabel("")
    problem.textColor = .systemRed
    problem.setAccessibilityIdentifier(id)
    problem.isHidden = true
    return problem
}

/// A view of `views` top to bottom, its own edges at theirs
@MainActor
private func column(_ views: [NSView], spacing: CGFloat) -> NSStackView {
    let stack = NSStackView(views: views)
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = spacing
    return stack
}

/// The window of a sheet: no title bar of its own, Esc as Cancel
@MainActor
private func sheetWindow(_ title: String, id: String) -> NSWindow {
    let window = TextDialogWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 200), styleMask: [.titled],
                                  backing: .buffered, defer: true)
    window.autorecalculatesKeyViewLoop = true
    window.title = title
    window.identifier = NSUserInterfaceItemIdentifier(id)
    return window
}

/// `window` as tall as its content asks, its top kept where it is
@MainActor
private func fit(_ window: NSWindow) {
    guard let content = window.contentView else { return }
    content.layoutSubtreeIfNeeded()
    let size = content.fittingSize
    var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
    guard frame.size != window.frame.size else { return }
    frame.origin = NSPoint(x: window.frame.minX, y: window.frame.maxY - frame.height)
    window.setFrame(frame, display: true, animate: window.isVisible)
}

// ---- Set Up Sync ----

/// Set Up Sync, a sheet of two steps: where the vault is (a folder, or S3-compatible storage), looked at with Next;
/// then the passphrase that starts a new vault there (twice) or joins the one there (once), the name of this computer
/// and what to sync. Turn On Sync turns it on and closes the sheet.
@MainActor
final class SyncSetupSheet: NSObject, NSTextFieldDelegate {
    private static var shown: SyncSetupSheet?
    /// the open sheet, for the UI test and the core's events
    static var current: SyncSetupSheet? { shown }

    let window: NSWindow
    private let core: Core
    private let width: CGFloat = 460
    private let content = NSStackView()

    // where
    let folderRadio = NSButton(radioButtonWithTitle: Text.uiSyncFolder.text, target: nil, action: nil)
    let bucketRadio = NSButton(radioButtonWithTitle: Text.uiSyncBucket.text, target: nil, action: nil)
    private(set) var folder: URL?
    let folderPath = NSTextField(labelWithString: Text.uiSyncFolderNone.text)
    let chooseButton = NSButton(title: Text.uiSyncChooseFolder.opens, target: nil, action: nil)
    let endpoint = NSTextField(string: "https://")
    let region = NSTextField(string: "")
    let bucket = NSTextField(string: "")
    let prefix = NSTextField(string: "")
    let accessKey = NSTextField(string: "")
    let secretKey = NSSecureTextField(string: "")
    private var whereGrid = NSGridView()
    private var whereView = NSView()
    /// the rows of the folder's grid and the bucket's, shown by the kind chosen
    private var folderRows: [Int] = []
    private var bucketRows: [Int] = []

    // the passphrase
    private(set) var join = false
    private var passphraseView: NSView?
    private(set) var pair: PassphrasePair?
    let joinField = NSSecureTextField(string: "")
    let nameField = NSTextField(string: Host.current().localizedName ?? "")
    let whatButton = NSButton()
    private let whatLabel = NSButton()
    private var whatList = NSView()
    private(set) var boxes: [(setting: Setting, box: NSButton)] = []
    private var place: SyncPlace?

    let problem = problemLabel(id: "sync.problem")
    private let spinner = busySpinner()
    private(set) var back: NSButton!
    private(set) var cancel: NSButton!
    private(set) var next: NSButton!
    private(set) var turnOn: NSButton!
    private var probing = false
    private var turnedOn = false

    init(core: Core) {
        self.core = core
        window = sheetWindow(Text.uiSyncSetUp.title, id: "sync.setup")
        super.init()
        back = keyButton(Text.uiGoBack.text, self, #selector(backClicked), "sync.back")
        cancel = keyButton(Text.uiCancel.text, self, #selector(cancelClicked), "sync.cancel")
        cancel.keyEquivalent = "\u{1b}"
        next = keyButton(Text.uiSyncNext.text, self, #selector(nextClicked), "sync.next")
        turnOn = keyButton(Text.uiSyncTurnOn.text, self, #selector(turnOnClicked), "sync.turnOn")
        for button in [back!, cancel!, next!, turnOn!] {
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        }
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        // as Apple's assistants have them: Cancel at the left, Go Back beside the step's own button at the right
        let buttons = NSStackView(views: [HelpButton("sync"), cancel, spacer, spinner, back, next, turnOn])
        buttons.spacing = 12
        whereView = makeWhere()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 16
        content.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        content.setViews([whereView, problem, buttons], in: .top)
        for view in [whereView, problem, buttons] {
            view.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        window.contentView = content
        showWhere()
    }

    /// Set Up Sync over `parent`; true once sync is on
    func run(on parent: NSWindow?) -> Bool {
        SyncSetupSheet.shown = self
        runSheet(window, on: parent)
        SyncSetupSheet.shown = nil
        pair?.wipe()
        joinField.stringValue = ""
        secretKey.stringValue = ""
        return turnedOn
    }

    // ---- where ----

    private func makeWhere() -> NSView {
        folderRadio.target = self
        folderRadio.action = #selector(kindChosen)
        folderRadio.state = .on
        folderRadio.setAccessibilityIdentifier("sync.kind.folder")
        bucketRadio.target = self
        bucketRadio.action = #selector(kindChosen)
        bucketRadio.setAccessibilityIdentifier("sync.kind.bucket")
        folderPath.lineBreakMode = .byTruncatingMiddle
        folderPath.textColor = .secondaryLabelColor
        folderPath.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        folderPath.setAccessibilityIdentifier("sync.folder")
        chooseButton.target = self
        chooseButton.action = #selector(chooseClicked)
        chooseButton.setAccessibilityIdentifier("sync.chooseFolder")
        chooseButton.setContentHuggingPriority(.required, for: .horizontal)
        let fields: [(Text, NSTextField, String)] = [
            (.uiSyncEndpoint, endpoint, "sync.endpoint"), (.uiSyncRegion, region, "sync.region"),
            (.uiSyncBucketName, bucket, "sync.bucket"), (.uiSyncPrefix, prefix, "sync.prefix"),
            (.uiSyncAccessKey, accessKey, "sync.accessKey"), (.uiSyncSecretKey, secretKey, "sync.secretKey"),
        ]
        let labels = [Text.uiSettingsLabel.text(["label": Text.uiSyncWhere.text]), Text.uiSyncFolderLabel.text]
            + fields.map(\.0.text)
        let labelWidth = labels.map { ceil(NSTextField(labelWithString: $0).intrinsicContentSize.width) }.max() ?? 0
        let room = width - labelWidth - 8
        let path = NSStackView(views: [folderPath, chooseButton])
        path.alignment = .firstBaseline
        path.spacing = 8
        let grid = NSGridView()
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        grid.addRow(with: [formLabel(labels[0]), folderRadio])
        grid.addRow(with: [NSGridCell.emptyContentView, indentedNote(Text.uiSyncFolderNote.text, room)])
        grid.addRow(with: [NSGridCell.emptyContentView, bucketRadio])
        grid.addRow(with: [NSGridCell.emptyContentView, indentedNote(Text.uiSyncBucketNote.text, room)])
        grid.row(at: 1).topPadding = -4
        grid.row(at: 3).topPadding = -4
        grid.addRow(with: [formLabel(labels[1]), path])
        folderRows = [grid.numberOfRows - 1]
        for (label, field, id) in fields {
            field.setAccessibilityIdentifier(id)
            field.setAccessibilityLabel(fieldTitle(label.text))
            field.delegate = self
            field.lineBreakMode = .byTruncatingTail
            field.cell?.isScrollable = true
            grid.addRow(with: [formLabel(label.text), field])
            bucketRows.append(grid.numberOfRows - 1)
        }
        grid.row(at: folderRows[0]).topPadding = 12
        grid.row(at: bucketRows[0]).topPadding = 12
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 0).width = labelWidth
        grid.column(at: 1).xPlacement = .fill
        grid.rowAlignment = .firstBaseline
        whereGrid = grid
        let view = column([sheetHeading(Text.uiSyncSetUp.title), grid], spacing: 16)
        grid.widthAnchor.constraint(equalToConstant: width).isActive = true
        return view
    }

    /// a note under a radio button, where its title starts
    private func indentedNote(_ words: String, _ room: CGFloat) -> NSView {
        let note = smallNote(words, width: room - 20)
        let stack = NSStackView(views: [note])
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        return stack
    }

    /// the place typed, nil while something it needs is missing
    var typedPlace: SyncPlace? {
        if folderRadio.state == .on {
            return folder.map { SyncPlace(folder: $0.path) }
        }
        let text = { (field: NSTextField) in field.stringValue.trimmingCharacters(in: .whitespaces) }
        let place = SyncPlace(folder: nil, endpoint: text(endpoint), region: text(region), bucket: text(bucket),
                              prefix: text(prefix), accessKey: text(accessKey), secret: secretKey.stringValue)
        let complete = !place.bucket.isEmpty && !place.accessKey.isEmpty && !place.secret.isEmpty
            && place.endpoint.count > "https://".count
        return complete ? place : nil
    }

    private func showWhere() {
        let onFolder = folderRadio.state == .on
        folderRows.forEach { whereGrid.row(at: $0).isHidden = !onFolder }
        bucketRows.forEach { whereGrid.row(at: $0).isHidden = onFolder }
        update()
    }

    /// what can be pressed: Next once the place is complete, Turn On Sync once the passphrase can be used
    private func update() {
        let first = passphraseView == nil
        back.isHidden = first
        next.isHidden = !first
        turnOn.isHidden = first
        // the step's own button is the default: the other one's key taken away first, as a window has one
        let (current, other) = first ? (next!, turnOn!) : (turnOn!, next!)
        other.keyEquivalent = ""
        current.keyEquivalent = "\r"
        window.defaultButtonCell = current.cell as? NSButtonCell
        next.isEnabled = !probing && typedPlace != nil
        let typed = join ? !joinField.stringValue.isEmpty : pair?.acceptable ?? false
        turnOn.isEnabled = !probing && typed && !nameField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func controlTextDidChange(_ notification: Notification) {
        update()
    }

    @objc private func kindChosen(_ sender: NSButton) {
        folderRadio.state = sender === folderRadio ? .on : .off
        bucketRadio.state = sender === bucketRadio ? .on : .off
        problem.isHidden = true
        showWhere()
        fit(window)
        if sender === bucketRadio {
            window.makeFirstResponder(endpoint)
        }
    }

    @objc private func chooseClicked() {
        guard let chosen = folderPanel(title: Text.uiSyncChooseFolderTitle.text) else { return }
        folder = chosen
        folderPath.stringValue = chosen.path
        folderPath.toolTip = chosen.path
        folderPath.textColor = .labelColor
        problem.isHidden = true
        update()
    }

    private func say(_ reason: String) {
        problem.stringValue = reason.isEmpty ? Text.uiUnknownReason.text : reason
        problem.isHidden = false
        fit(window)
    }

    private func setBusy(_ busy: Bool) {
        probing = busy
        busy ? spinner.startAnimation(nil) : spinner.stopAnimation(nil)
        update()
    }

    /// Next: the place looked at on the core's runtime; `probed` hears the answer
    @objc private func nextClicked() {
        guard !probing, let place = typedPlace else { return }
        self.place = place
        problem.isHidden = true
        setBusy(true)
        place.withC { pe_settings_sync_probe_start(core.handle, $0, $1) }
        probed()
    }

    /// the answer of the place looked at, when the core has it (`SettingsSyncChanged`, or a turn after Next)
    func probed() {
        guard probing else { return }
        var error: UnsafeMutablePointer<CChar>?
        let found = pe_settings_sync_probe(core.handle, &error)
        let reason = taken(error) ?? ""
        switch found {
        case PE_SYNC_PROBE_WAITING:
            // the event may come before the answer is kept: looked at again shortly
            after(0.2) { [weak self] in self?.probed() }
        case PE_SYNC_PROBE_PROBLEM:
            setBusy(false)
            say(reason)
        default:
            setBusy(false)
            showPassphrase(join: found == PE_SYNC_PROBE_VAULT)
        }
    }

    // ---- the passphrase ----

    private func showPassphrase(join: Bool) {
        self.join = join
        let view = makePassphrase(join: join)
        passphraseView = view
        whereView.isHidden = true
        content.insertView(view, at: 0, in: .top)
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        problem.isHidden = true
        update()
        fit(window)
        window.makeFirstResponder(join ? joinField : pair?.fields[0])
    }

    private func makePassphrase(join: Bool) -> NSView {
        let heading = sheetHeading(join ? Text.uiSyncJoinTitle.text : Text.uiSyncStartTitle.text)
        heading.setAccessibilityIdentifier("sync.heading")
        let intro = wrappingLabel(join ? Text.uiSyncJoinNote.text : Text.uiSyncStartNote.text)
        intro.preferredMaxLayoutWidth = width
        let nameLabel = Text.uiSyncName.text
        let passLabels = join ? [Text.uiKeysPassphrase.text] : [Text.uiKeysPassphrase.text, Text.uiKeysPassphraseAgain.text]
        let labelWidth = (passLabels + [nameLabel]).map { ceil(NSTextField(labelWithString: $0).intrinsicContentSize.width) }
            .max() ?? 0
        nameField.setAccessibilityIdentifier("sync.name")
        nameField.setAccessibilityLabel(fieldTitle(nameLabel))
        nameField.delegate = self
        nameField.lineBreakMode = .byTruncatingTail
        nameField.cell?.isScrollable = true
        var views: [NSView] = [heading, intro]
        var stackAfterPair: NSView?
        let nameGrid = NSGridView(views: [[formLabel(nameLabel), nameField]])
        if join {
            joinField.setAccessibilityIdentifier("sync.passphrase.field.0")
            joinField.setAccessibilityLabel(fieldTitle(passLabels[0]))
            joinField.delegate = self
            nameGrid.insertRow(at: 0, with: [formLabel(passLabels[0]), joinField])
            views.append(nameGrid)
        } else {
            // the rule of key backups: the core's words of what is typed, under the two fields
            let pair = PassphrasePair(id: "sync.passphrase", width: width)
            pair.changed = { [weak self] in self?.update() }
            pair.grid.column(at: 0).width = labelWidth
            self.pair = pair
            views += [pair.view, nameGrid]
            stackAfterPair = pair.view
        }
        for grid in [nameGrid] {
            grid.rowSpacing = 8
            grid.columnSpacing = 8
            grid.column(at: 0).xPlacement = .trailing
            grid.column(at: 0).width = labelWidth
            grid.column(at: 1).xPlacement = .fill
            grid.rowAlignment = .firstBaseline
            grid.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if join {
            views.append(indentedBy(labelWidth + 8, smallNote(Text.uiSyncMergeNote.text, width: width - labelWidth - 8)))
        }
        views.append(makeWhat())
        let stack = column(views, spacing: 12)
        stack.setCustomSpacing(16, after: heading)
        // the room under the passphrases is kept for what the core says of them
        stackAfterPair.map { stack.setCustomSpacing(2, after: $0) }
        if let last = views.dropLast().last {
            stack.setCustomSpacing(16, after: last)
        }
        return stack
    }

    private func indentedBy(_ inset: CGFloat, _ view: NSView) -> NSView {
        let stack = NSStackView(views: [view])
        stack.edgeInsets = NSEdgeInsets(top: 0, left: inset, bottom: 0, right: 0)
        return stack
    }

    /// What to sync, folded into one line that says Everything or Some things left out; open, a check box for each
    /// kind of data and secret, a secret's under its data's and off while that is
    private func makeWhat() -> NSView {
        whatButton.bezelStyle = .disclosure
        whatButton.setButtonType(.pushOnPushOff)
        whatButton.title = ""
        whatButton.state = .off
        whatButton.target = self
        whatButton.action = #selector(whatToggled(_:))
        whatButton.setAccessibilityIdentifier("sync.what")
        whatButton.setAccessibilityLabel(Text.uiSyncWhat.text)
        // the words beside the triangle open it too, as the system's disclosure lines do
        whatLabel.isBordered = false
        whatLabel.target = self
        whatLabel.action = #selector(whatToggled(_:))
        whatLabel.setAccessibilityIdentifier("sync.what.summary")
        let line = NSStackView(views: [whatButton, whatLabel])
        line.spacing = 4
        line.alignment = .centerY
        var rows: [NSView] = []
        for (setting, _) in syncFlags {
            let box = NSButton(checkboxWithTitle: hyphensKept(setting.label.text), target: self, action: #selector(boxChanged))
            box.state = .on
            box.setAccessibilityIdentifier("sync.what.\(setting)")
            boxes.append((setting, box))
            rows.append(setting.dependsOn == nil ? box : indentedBy(20, box))
        }
        rows.append(smallNote(Text.uiSyncWhatNote.text, width: width - 20))
        let list = column(rows, spacing: 6)
        list.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        list.isHidden = true
        whatList = list
        showWhat()
        return column([line, list], spacing: 8)
    }

    /// the folded line's words, and each secret's box on only while its data's is
    private func showWhat() {
        let all = boxes.allSatisfy { $0.box.state == .on }
        let summary = Text.uiSettingsLabel.text(["label": Text.uiSyncWhat.text]) + " "
            + (all ? Text.uiSyncEverything.text : Text.uiSyncSomeLeftOut.text)
        whatLabel.title = summary
        for (setting, box) in boxes {
            if let parent = setting.dependsOn, let of = boxes.first(where: { $0.setting == parent }) {
                box.isEnabled = of.box.state == .on
            }
        }
    }

    @objc private func whatToggled(_ sender: NSButton) {
        if sender === whatLabel {
            whatButton.state = whatButton.state == .on ? .off : .on
        }
        whatList.isHidden = whatButton.state == .off
        fit(window)
    }

    @objc private func boxChanged() {
        showWhat()
    }

    /// what to sync as the boxes have it (a secret's box that is off for its data counts as off)
    var choice: PeSyncChoice {
        var choice = pe_sync_choice_default()
        for (setting, flag) in syncFlags {
            choice[keyPath: flag] = boxes.first { $0.setting == setting }.map { $0.box.state == .on && $0.box.isEnabled } ?? true
        }
        return choice
    }

    @objc private func backClicked() {
        passphraseView?.removeFromSuperview()
        passphraseView = nil
        pair?.wipe()
        pair = nil
        joinField.stringValue = ""
        boxes = []
        whereView.isHidden = false
        problem.isHidden = true
        update()
        fit(window)
    }

    /// Turn On Sync: on the core's runtime, as the passphrase is worked through Argon2 and the place written; the
    /// sheet closes once it is on, or says why not
    @objc private func turnOnClicked() {
        update()
        guard turnOn.isEnabled, let place else { return }
        let passphrase = join ? joinField.stringValue : pair?.passphrase ?? ""
        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        let (handle, choice) = (Handed(value: core.handle), choice)
        problem.isHidden = true
        setBusy(true)
        inBackground({ () -> String? in
            let strings = CStrings()
            defer { strings.wipe() }
            var error: UnsafeMutablePointer<CChar>?
            let on = place.withC { pe_settings_sync_turn_on(handle.value, $0, $1, strings.add(passphrase), name, choice, &error) }
            let reason = taken(error)
            return on ? nil : reason ?? ""
        }) { [self] refused in
            setBusy(false)
            guard let refused else {
                turnedOn = true
                NSApp.stopModal()
                SettingsWindow.current?.refreshSync()
                AppDelegate.shared?.main?.setStatus(Text.uiSyncOn.text)
                return
            }
            say(refused)
            window.makeFirstResponder(join ? joinField : pair?.fields[0])
        }
    }

    @objc private func cancelClicked() {
        NSApp.stopModal()
    }
}

// ---- Computers and History ----

/// A cell of two lines: the name, and under it in the secondary look what is said of it
@MainActor
private func twoLineCell(_ table: NSTableView, _ id: String) -> NSTableCellView {
    let identifier = NSUserInterfaceItemIdentifier(id)
    if let cell = table.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView { return cell }
    let cell = NSTableCellView()
    cell.identifier = identifier
    let first = NSTextField(labelWithString: "")
    first.lineBreakMode = .byTruncatingTail
    let second = NSTextField(labelWithString: "")
    second.lineBreakMode = .byTruncatingTail
    second.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
    second.textColor = .secondaryLabelColor
    second.identifier = NSUserInterfaceItemIdentifier("second")
    let stack = NSStackView(views: [first, second])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 1
    stack.translatesAutoresizingMaskIntoConstraints = false
    cell.addSubview(stack)
    cell.textField = first
    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
        stack.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
        stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
    ])
    return cell
}

@MainActor
private func secondLine(_ cell: NSTableCellView) -> NSTextField? {
    cell.subviews.first.flatMap { ($0 as? NSStackView)?.arrangedSubviews.last as? NSTextField }
}

/// `table` of one column without a header in a scroll with the list's border
@MainActor
private func listScroll(_ table: NSTableView, id: String, rowHeight: CGFloat) -> NSScrollView {
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("row"))
    column.resizingMask = .autoresizingMask
    table.addTableColumn(column)
    table.headerView = nil
    table.style = .fullWidth
    table.rowHeight = rowHeight
    table.usesAlternatingRowBackgroundColors = true
    table.setAccessibilityIdentifier(id)
    let scroll = NSScrollView()
    scroll.documentView = table
    scroll.hasVerticalScroller = true
    scroll.borderType = .bezelBorder
    return scroll
}

/// A sheet with a heading, its note, a list and what is under the list, and Done: Computers and History
@MainActor
class SyncListSheet: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let window: NSWindow
    let core: Core
    let table = NSTableView()
    /// what the list says when it has no rows
    let empty = NSTextField(labelWithString: "")

    init(core: Core, title: String, note: String, id: String, under: NSView, extra: NSView? = nil) {
        self.core = core
        window = sheetWindow(title, id: id)
        super.init()
        let width: CGFloat = 440
        let heading = sheetHeading(title)
        let said = smallNote(note, width: width)
        let scroll = listScroll(table, id: "\(id).list", rowHeight: 36)
        table.dataSource = self
        table.delegate = self
        empty.textColor = .secondaryLabelColor
        empty.translatesAutoresizingMaskIntoConstraints = false
        empty.setAccessibilityIdentifier("\(id).empty")
        let done = keyButton(Text.uiDone.text, self, #selector(doneClicked), "\(id).done")
        done.keyEquivalent = "\r"
        done.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        let content = NSView()
        for view in [heading, said, scroll, under, done] + (extra.map { [$0] } ?? []) {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        content.addSubview(empty)
        // the − of a list sits on its lower edge, as the system's lists have it; a push button under it
        let gap: CGFloat = under is NSSegmentedControl ? -1 : 8
        let last = extra ?? under
        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            heading.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            said.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 6),
            said.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            said.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scroll.topAnchor.constraint(equalTo: said.bottomAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scroll.heightAnchor.constraint(equalToConstant: extra == nil ? 200 : 144),
            empty.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            empty.centerYAnchor.constraint(equalTo: scroll.centerYAnchor),
            under.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: gap),
            under.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            done.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 20),
            done.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            done.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
        ])
        if let extra {
            NSLayoutConstraint.activate([
                extra.topAnchor.constraint(equalTo: under.bottomAnchor, constant: 20),
                extra.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
                extra.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            ])
        }
        window.contentView = content
    }

    @objc private func doneClicked() {
        NSApp.stopModal()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { 0 }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? { nil }
}

/// Computers: the computers that sync through the place, read by the core, this one marked; the − under the list
/// takes the one selected out of the sync, asked first
@MainActor
final class SyncComputersSheet: SyncListSheet {
    private static var shown: SyncComputersSheet?
    /// the open sheet, for the UI test and the core's events
    static var current: SyncComputersSheet? { shown }
    let remove = NSSegmentedControl()
    private(set) var computers: [SyncComputer]?

    init(core: Core) {
        // the − under the list's corner, as the system's lists have it
        remove.segmentStyle = .smallSquare
        remove.trackingMode = .momentary
        remove.segmentCount = 1
        remove.setImage(NSImage(named: NSImage.removeTemplateName), forSegment: 0)
        remove.setWidth(24, forSegment: 0)
        remove.setAccessibilityIdentifier("sync.computers.remove")
        remove.setToolTip(Text.uiRemove.text, forSegment: 0)
        remove.setAccessibilityLabel(Text.uiRemove.text)
        super.init(core: core, title: Text.uiSyncComputersTitle.text, note: Text.uiSyncComputersNote.text,
                   id: "sync.computers", under: remove)
        remove.target = self
        remove.action = #selector(removeClicked)
        empty.stringValue = Text.uiSyncLoading.text
        pe_settings_sync_computers_start(core.handle)
        reload()
    }

    func run(on parent: NSWindow?) {
        SyncComputersSheet.shown = self
        runSheet(window, on: parent)
        SyncComputersSheet.shown = nil
    }

    /// the computers as the core read them, or that they are being read
    func reload() {
        computers = core.syncComputers
        table.reloadData()
        empty.isHidden = computers != nil
        updateRemove()
    }

    private func updateRemove() {
        let row = table.selectedRow
        remove.setEnabled(computers.map { $0.indices.contains(row) && !$0[row].this } ?? false, forSegment: 0)
    }

    @objc private func removeClicked() {
        let row = table.selectedRow
        guard let computers, computers.indices.contains(row), !computers[row].this else { return }
        let computer = computers[row]
        guard ask(Text.uiSyncRemoveAsk.text(["name": computer.name]), title: Text.uiSyncComputersTitle.text,
                  yes: Text.uiRemove.text, no: Text.uiCancel.text, destructive: true) else { return }
        // the core says when it is done, and reads them again
        pe_settings_sync_remove_computer(core.handle, computer.device)
    }

    override func numberOfRows(in tableView: NSTableView) -> Int {
        computers?.count ?? 0
    }

    override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = twoLineCell(tableView, "sync.computer")
        guard let computers, computers.indices.contains(row) else { return cell }
        let computer = computers[row]
        cell.textField?.stringValue = computer.name
        secondLine(cell)?.stringValue = computer.this ? Text.uiSyncThisComputer.text
            : Text.uiSyncSeen.text(["when": computer.seen])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateRemove()
    }
}

/// History: the edits another computer made at the same time as this one, which this one's replaced (Restore puts
/// the one selected back), and under them the restore points, how things were before a sync took something away
/// (Open shows one in the Import window, which brings back what the user chooses of it)
@MainActor
final class SyncHistorySheet: SyncListSheet {
    private static var shown: SyncHistorySheet?
    /// the open sheet, for the UI test
    static var current: SyncHistorySheet? { shown }
    let restore = NSButton()
    let points = NSTableView()
    let open = NSButton()
    private let noPoints = NSTextField(labelWithString: Text.uiSyncRestorePointsEmpty.text)
    private(set) var edits: [SyncEdit] = []
    private(set) var restorePoints: [(path: String, when: String)] = []

    init(core: Core) {
        restore.title = Text.uiSyncRestore.text
        restore.bezelStyle = .push
        restore.setAccessibilityIdentifier("sync.history.restore")
        open.title = Text.uiSyncOpenPoint.opens
        open.bezelStyle = .push
        open.setAccessibilityIdentifier("sync.points.open")
        let width: CGFloat = 440
        let heading = NSTextField(labelWithString: Text.uiSyncRestorePoints.text)
        heading.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        let note = smallNote(Text.uiSyncRestorePointsNote.text, width: width)
        let scroll = listScroll(points, id: "sync.points.list", rowHeight: 24)
        scroll.heightAnchor.constraint(equalToConstant: 96).isActive = true
        scroll.widthAnchor.constraint(equalToConstant: width).isActive = true
        noPoints.textColor = .secondaryLabelColor
        noPoints.translatesAutoresizingMaskIntoConstraints = false
        noPoints.setAccessibilityIdentifier("sync.points.empty")
        let section = column([heading, note, scroll, open], spacing: 6)
        section.setCustomSpacing(12, after: note)
        section.setCustomSpacing(8, after: scroll)
        section.addSubview(noPoints)
        NSLayoutConstraint.activate([
            noPoints.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            noPoints.centerYAnchor.constraint(equalTo: scroll.centerYAnchor),
        ])
        super.init(core: core, title: Text.uiSyncHistoryTitle.text, note: Text.uiSyncHistoryNote.text,
                   id: "sync.history", under: restore, extra: section)
        restore.target = self
        restore.action = #selector(restoreClicked)
        open.target = self
        open.action = #selector(openClicked)
        points.dataSource = self
        points.delegate = self
        points.doubleAction = #selector(openClicked)
        points.target = self
        empty.stringValue = Text.uiSyncHistoryEmpty.text
        reload()
    }

    func run(on parent: NSWindow?) {
        SyncHistorySheet.shown = self
        runSheet(window, on: parent)
        SyncHistorySheet.shown = nil
    }

    func reload() {
        edits = core.syncHistory
        table.reloadData()
        empty.isHidden = !edits.isEmpty
        restore.isEnabled = edits.indices.contains(table.selectedRow)
        restorePoints = []
        if let list = pe_settings_sync_restore_points(core.handle) {
            restorePoints = (0..<pe_settings_sync_restore_points_count(list))
                .compactMap { pe_settings_sync_restore_points_get(list, $0)?.pointee }
                .map { (text($0.path), text($0.when)) }
            pe_settings_sync_restore_points_free(list)
        }
        points.reloadData()
        noPoints.isHidden = !restorePoints.isEmpty
        open.isEnabled = restorePoints.indices.contains(points.selectedRow)
    }

    @objc private func restoreClicked() {
        let row = table.selectedRow
        guard edits.indices.contains(row) else { return }
        _ = SyncEvents.withPrefs { pe_settings_sync_restore(core.handle, edits[row].id, $0) }
        reload()
    }

    /// the restore point selected read as a setup file, then the Import window on it, as for a file opened
    @objc private func openClicked() {
        let row = points.selectedRow
        guard restorePoints.indices.contains(row) else { return }
        var error: UnsafeMutablePointer<CChar>?
        guard let file = pe_settings_sync_restore_point_read(core.handle, restorePoints[row].path, &error) else {
            let reason = taken(error) ?? ""
            inform(reason.isEmpty ? Text.uiUnknownReason.text : reason, title: Text.uiSyncRestorePoints.text, style: .warning)
            return
        }
        SetupFiles.importRead(core: core, SetupFile(file), title: Text.uiSetupImportTitle.text)
    }

    override func numberOfRows(in tableView: NSTableView) -> Int {
        tableView === points ? restorePoints.count : edits.count
    }

    override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView === points {
            let cell = twoLineCell(tableView, "sync.point")
            cell.textField?.stringValue = restorePoints.indices.contains(row) ? restorePoints[row].when : ""
            secondLine(cell)?.isHidden = true
            return cell
        }
        let cell = twoLineCell(tableView, "sync.edit")
        guard edits.indices.contains(row) else { return cell }
        let edit = edits[row]
        cell.textField?.stringValue = edit.value.isEmpty ? edit.item : edit.item + ": " + edit.value
        secondLine(cell)?.stringValue = Text.uiSyncHistoryRow.text(["source": edit.source, "when": edit.when])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        restore.isEnabled = edits.indices.contains(table.selectedRow)
        open.isEnabled = restorePoints.indices.contains(points.selectedRow)
    }
}
