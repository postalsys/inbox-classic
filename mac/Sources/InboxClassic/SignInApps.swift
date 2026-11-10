// Sign-in apps: the Sign-in Apps window (File > Accounts) with the built-in Google and Microsoft clients and the OAuth
// clients the user added, each turned on or off for new accounts, and the editor of an added one. What is typed goes
// to the core as it is; the core checks the issuer (OpenID Connect discovery) and the rest before saving.
import AppKit
import CInboxClassic

private let appSecurityNames = ["SSL/TLS", "STARTTLS"]

// ---- the editor ----

/// edits `app` (nil: adds one); the id saved, 0 when cancelled
@MainActor
func signInAppEditor(core: Core, app: SignInApps.App?) -> Int64 {
    SignInAppEditor(core: core, app: app).run()
}

@MainActor
private final class SignInAppEditor: NSObject, NSTextFieldDelegate {
    private let window: NSWindow
    private let core: Core
    private let id: Int64
    private let hadSecret: Bool
    private var presets: [(name: String, issuer: String, scopes: String, imapHost: String, imapPort: UInt16, imapSecurity: PeSecurity,
                           smtpHost: String, smtpPort: UInt16, smtpSecurity: PeSecurity)] = []
    private let name = NSTextField(string: "")
    private let issuer = NSTextField(string: "")
    private let clientId = NSTextField(string: "")
    private let secret = NSSecureTextField(string: "")
    private let removeSecret = NSButton(checkboxWithTitle: Text.uiRemoveSecret.text, target: nil, action: nil)
    private let scopes = NSTextField(string: "")
    private let imapHost = NSTextField(string: "")
    private let imapPort = NSTextField(string: "")
    private let imapSecurity = NSPopUpButton(frame: .zero, pullsDown: false)
    private let smtpHost = NSTextField(string: "")
    private let smtpPort = NSTextField(string: "")
    private let smtpSecurity = NSPopUpButton(frame: .zero, pullsDown: false)
    private let register = NSTextField(wrappingLabelWithString: "")
    private let redirect = NSTextField(string: "")
    private var saved: Int64 = 0

    init(core: Core, app: SignInApps.App?) {
        self.core = core
        id = app?.id ?? 0
        hadSecret = app?.hasSecret ?? false
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 520), styleMask: [.titled], backing: .buffered,
                          defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = app == nil ? Text.uiAddSignInAppTitle.text : Text.uiSignInApp.text
        window.identifier = NSUserInterfaceItemIdentifier("signin.editor")
        super.init()
        if let list = pe_sign_in_presets() {
            defer { pe_sign_in_preset_list_free(list) }
            for index in 0..<pe_sign_in_preset_list_count(list) {
                guard let preset = pe_sign_in_preset_list_get(list, index)?.pointee else { continue }
                presets.append((text(preset.name), text(preset.issuer), text(preset.scopes), text(preset.imap_host), preset.imap_port,
                                preset.imap_security, text(preset.smtp_host), preset.smtp_port, preset.smtp_security))
            }
        }
        name.stringValue = app?.name ?? ""
        issuer.stringValue = app?.issuer ?? ""
        clientId.stringValue = app?.clientId ?? ""
        scopes.stringValue = app?.scopes ?? ""
        imapHost.stringValue = app?.imapHost ?? ""
        imapPort.stringValue = "\(app?.imapPort ?? 993)"
        smtpHost.stringValue = app?.smtpHost ?? ""
        smtpPort.stringValue = "\(app?.smtpPort ?? 465)"
        for (popup, security) in [(imapSecurity, app?.imapSecurity ?? PE_SECURITY_TLS), (smtpSecurity, app?.smtpSecurity ?? PE_SECURITY_TLS)] {
            popup.addItems(withTitles: appSecurityNames)
            popup.selectItem(at: security == PE_SECURITY_START_TLS ? 1 : 0)
        }
        redirect.isEditable = false
        redirect.isSelectable = true
        issuer.delegate = self
        for (field, id) in [(name, "signin.name"), (issuer, "signin.issuer"), (clientId, "signin.client"), (secret, "signin.secret"),
                            (scopes, "signin.scopes"), (imapHost, "signin.imap"), (smtpHost, "signin.smtp"), (redirect, "signin.redirect")] {
            field.setAccessibilityIdentifier(id)
        }
        window.contentView = layout()
        window.initialFirstResponder = name
        showRegistration()
    }

    private func layout() -> NSView {
        let intro = wrappingLabel(Text.uiSignInAppIntro.text)
        let presetButtons = NSStackView(views: presets.enumerated().map { index, preset in
            let button = NSButton(title: preset.name, target: self, action: #selector(fillPreset(_:)))
            button.tag = index
            button.setAccessibilityIdentifier("signin.preset.\(index)")
            return button
        })
        let check = NSButton(title: Text.uiCheck.text, target: self, action: #selector(checkClicked))
        check.setAccessibilityIdentifier("signin.check")
        let copy = NSButton(title: Text.uiButtonCopy.text, target: self, action: #selector(copyRedirect))
        let issuerRow = NSStackView(views: [issuer, check])
        let redirectRow = NSStackView(views: [redirect, copy])
        let server = { (host: NSTextField, port: NSTextField, security: NSPopUpButton) -> NSStackView in
            port.widthAnchor.constraint(equalToConstant: 56).isActive = true
            return NSStackView(views: [host, port, security])
        }
        var rows: [[NSView]] = [
            [NSTextField(labelWithString: Text.uiFillInFor.text), presetButtons],
            [NSTextField(labelWithString: Text.uiAppName.text), name],
            [NSTextField(labelWithString: Text.uiIssuer.text), issuerRow],
            [NSTextField(labelWithString: Text.uiClientId.text), clientId],
            // never shown again once saved: it is in the keychain
            [NSTextField(labelWithString: Text.uiClientSecret.text), secret],
        ]
        if hadSecret {
            rows.append([NSGridCell.emptyContentView, removeSecret])
        }
        rows += [
            [NSTextField(labelWithString: Text.uiScopes.text), scopes],
            [NSTextField(labelWithString: Text.uiImapServer.text), server(imapHost, imapPort, imapSecurity)],
            [NSTextField(labelWithString: Text.uiSmtpServer.text), server(smtpHost, smtpPort, smtpSecurity)],
        ]
        let grid = NSGridView(views: rows)
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).width = 380
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        let line = NSBox()
        line.boxType = .separator
        let registerTitle = NSTextField(labelWithString: Text.uiRegisterIt.text)
        registerTitle.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        let redirectGrid = NSGridView(views: [[NSTextField(labelWithString: Text.uiRedirectUri.text), redirectRow]])
        redirectGrid.column(at: 1).width = 380
        let cancel = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        let ok = NSButton(title: Text.uiOk.text, target: self, action: #selector(okClicked))
        ok.keyEquivalent = "\r"
        ok.setAccessibilityIdentifier("signin.ok")
        let buttons = buttonRow([cancel, ok])
        let stack = NSStackView(views: [intro, grid, line, registerTitle, register, redirectGrid, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        intro.widthAnchor.constraint(equalToConstant: 500).isActive = true
        register.widthAnchor.constraint(equalToConstant: 500).isActive = true
        line.widthAnchor.constraint(equalToConstant: 500).isActive = true
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        return stack
    }

    /// the redirect URI and how to register a client, for the issuer typed
    private func showRegistration() {
        issuer.stringValue.withCString { typed in
            redirect.stringValue = taken(pe_sign_in_redirect_uri(typed)) ?? ""
            register.stringValue = taken(pe_sign_in_register_hint(typed)) ?? ""
        }
    }

    func controlTextDidChange(_ notification: Notification) {
        showRegistration()
    }

    /// a preset fills in everything but the client; the name only when there is none yet
    @objc private func fillPreset(_ sender: NSButton) {
        let preset = presets[sender.tag]
        if name.stringValue.isEmpty {
            name.stringValue = Text.uiPresetAppName.text(["provider": preset.name])
        }
        issuer.stringValue = preset.issuer
        scopes.stringValue = preset.scopes
        imapHost.stringValue = preset.imapHost
        imapPort.stringValue = "\(preset.imapPort)"
        imapSecurity.selectItem(at: preset.imapSecurity == PE_SECURITY_START_TLS ? 1 : 0)
        smtpHost.stringValue = preset.smtpHost
        smtpPort.stringValue = "\(preset.smtpPort)"
        smtpSecurity.selectItem(at: preset.smtpSecurity == PE_SECURITY_START_TLS ? 1 : 0)
        showRegistration()
        window.makeFirstResponder(clientId)
    }

    @objc private func copyRedirect() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(redirect.stringValue, forType: .string)
    }

    /// checks the issuer typed (its discovery document), waiting with a window that can cancel it: whether it can be
    /// used, with what was found or why not
    private func checkIssuer() -> (usable: Bool, said: String) {
        let typed = issuer.stringValue
        var error: UnsafeMutablePointer<CChar>?
        let request = typed.withCString { pe_sign_in_app_check(core.handle, $0, &error) }
        let reason = taken(error)
        guard request != 0 else { return (false, reason ?? Text.uiIssuerNotChecked.text) }
        guard Waiting.wait(for: request, text: Text.macCheckingIssuer.text(["issuer": typed]), title: Text.uiSignInApp.text,
                           cancel: { pe_sign_in_app_check_cancel(self.core.handle, $0) }) else { return (false, "") }
        var found: UnsafeMutablePointer<CChar>?
        let usable = pe_sign_in_app_check_result(core.handle, request, &found)
        return (usable, taken(found) ?? "")
    }

    @objc private func checkClicked() {
        let (usable, said) = checkIssuer()
        if !said.isEmpty {
            inform(usable ? Text.uiIssuerUsable.text + "\n\n" + said : Text.uiIssuerUnusable.text(["reason": said]),
                   title: Text.uiCheck.text, style: usable ? .information : .warning)
        }
    }

    private func port(_ field: NSTextField) -> UInt16 {
        field.stringValue.count <= 5 ? UInt16(field.stringValue) ?? 0 : 0
    }

    /// OK: the issuer checked, then the app saved; the editor stays open (with the reason shown) when it can not be
    @objc private func okClicked() {
        let imap = port(imapPort)
        let smtp = port(smtpPort)
        guard imap != 0, smtp != 0 else {
            inform(Text.uiPortsInvalid.text, title: Text.uiSignInApp.text, style: .warning)
            return
        }
        let (usable, said) = checkIssuer()
        guard usable else {
            if !said.isEmpty {
                inform(Text.uiIssuerUnusable.text(["reason": said]), title: Text.uiSignInApp.text, style: .warning)
                window.makeFirstResponder(issuer)
            }
            return
        }
        let strings = CStrings()
        var form = PeSignInAppForm(
            name: strings.add(name.stringValue), issuer: strings.add(issuer.stringValue), client_id: strings.add(clientId.stringValue),
            scopes: strings.add(scopes.stringValue), imap_host: strings.add(imapHost.stringValue), imap_port: imap,
            imap_security: imapSecurity.indexOfSelectedItem == 1 ? PE_SECURITY_START_TLS : PE_SECURITY_TLS,
            smtp_host: strings.add(smtpHost.stringValue), smtp_port: smtp,
            smtp_security: smtpSecurity.indexOfSelectedItem == 1 ? PE_SECURITY_START_TLS : PE_SECURITY_TLS)
        let typedSecret = secret.stringValue
        let change = !typedSecret.isEmpty ? PE_SECRET_CHANGE_SET
            : hadSecret && removeSecret.state == .on ? PE_SECRET_CHANGE_REMOVE : PE_SECRET_CHANGE_KEEP
        var error: UnsafeMutablePointer<CChar>?
        let secretText = strings.add(typedSecret)
        let result = pe_sign_in_app_save(core.handle, id, &form, change, secretText, &error)
        strings.wipe()
        secret.stringValue = ""
        guard result != 0 else {
            inform(Text.uiSignInAppNotSaved.text(["reason": taken(error) ?? Text.uiUnknownReason.text]),
                   title: Text.uiSignInApp.text, style: .warning)
            return
        }
        saved = result
        NSApp.stopModal()
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    func run() -> Int64 {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        return saved
    }
}

// ---- the Sign-in Apps window ----

@MainActor
func signInAppsDialog(core: Core) {
    SignInAppsWindow(core: core).run()
}

@MainActor
private final class SignInAppsWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let window: NSWindow
    private let core: Core
    private let table = NSTableView()
    private let note = NSTextField(wrappingLabelWithString: "")
    private let edit = NSButton(title: Text.macEditButton.text, target: nil, action: nil)
    private let remove = NSButton(title: Text.uiRemove.text, target: nil, action: nil)
    private var apps: [SignInApps.App] = []

    init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 340), styleMask: [.titled, .resizable],
                          backing: .buffered, defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiSignInApps.text
        window.identifier = NSUserInterfaceItemIdentifier("signin.apps")
        super.init()
        for (id, title, width) in [("on", "", 24.0), ("name", Text.uiColName.text, 210.0), ("issuer", Text.uiColIssuer.text, 200.0),
                                   ("used", Text.uiColUsedBy.text, 110.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            table.addTableColumn(column)
        }
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        // the last column takes the rest of the width, no wider
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.target = self
        table.doubleAction = #selector(editClicked)
        table.setAccessibilityIdentifier("signin.list")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let add = NSButton(title: Text.macAddButton.text, target: self, action: #selector(addClicked))
        add.setAccessibilityIdentifier("signin.add")
        edit.target = self
        edit.action = #selector(editClicked)
        remove.target = self
        remove.action = #selector(removeClicked)
        let close = NSButton(title: Text.uiClose.text, target: NSApp,
                             action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
        close.keyEquivalent = "\r"
        let side = NSStackView(views: [add, edit, remove, NSView(), close])
        side.orientation = .vertical
        side.alignment = .leading
        for button in [add, edit, remove, close] {
            button.widthAnchor.constraint(equalToConstant: 110).isActive = true
        }
        let intro = wrappingLabel(Text.uiSignInAppsIntro.text)
        let middle = NSStackView(views: [scroll, side])
        middle.alignment = .top
        let stack = NSStackView(views: [intro, middle, note])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        intro.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        note.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        middle.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        side.heightAnchor.constraint(equalTo: scroll.heightAnchor).isActive = true
        window.contentView = stack
        fill()
    }

    /// a row per app, the built-in ones first, checked when it is on; `select` stays selected
    private func fill(select: Int = 0) {
        apps = SignInApps(core: core).apps
        table.reloadData()
        if !apps.isEmpty {
            table.selectRowIndexes(IndexSet(integer: min(max(select, 0), apps.count - 1)), byExtendingSelection: false)
        }
        showSelected()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { apps.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let app = apps[row]
        let builtin = app.provider != PE_O_AUTH_PROVIDER_APP
        switch column?.identifier.rawValue {
        case "on":
            let box = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggled(_:)))
            box.state = app.enabled ? .on : .off
            box.tag = row
            box.setAccessibilityIdentifier("signin.on.\(row)")
            box.setAccessibilityLabel(Text.macUseForNewAccounts.text(["name": app.name]))
            return box
        case "name": return NSTextField(labelWithString: builtin ? Text.macBuiltIn.text(["name": app.name]) : app.name)
        case "issuer": return NSTextField(labelWithString: app.issuer)
        default: return NSTextField(labelWithString: app.usedBy.isEmpty ? Text.uiNoAccounts.text : app.usedBy)
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        showSelected()
    }

    private var selected: SignInApps.App? {
        apps.indices.contains(table.selectedRow) ? apps[table.selectedRow] : nil
    }

    /// what the selected app is: why a built-in one may be off, an added one's client; Edit and Remove for added ones
    private func showSelected() {
        let app = selected
        let added = app?.provider == PE_O_AUTH_PROVIDER_APP
        edit.isEnabled = added
        remove.isEnabled = added
        if let app, !added {
            note.stringValue = Text.uiBuiltInNote.text(["name": app.name]) + (app.enabled ? "" : " " + app.offReason)
        } else if let app {
            note.stringValue = app.hasSecret ? Text.uiClientWithSecret.text(["client": app.clientId])
                                             : Text.uiClientPublic.text(["client": app.clientId])
        } else {
            note.stringValue = ""
        }
    }

    @objc private func toggled(_ sender: NSButton) {
        let app = apps[sender.tag]
        pe_sign_in_app_set_enabled(core.handle, app.provider, app.id, sender.state == .on)
        fill(select: sender.tag)
    }

    @objc private func addClicked() {
        if signInAppEditor(core: core, app: nil) != 0 {
            fill(select: apps.count)
        }
    }

    @objc private func editClicked() {
        guard let app = selected, app.provider == PE_O_AUTH_PROVIDER_APP else { return }
        if signInAppEditor(core: core, app: app) != 0 {
            fill(select: table.selectedRow)
        }
    }

    @objc private func removeClicked() {
        guard let app = selected, app.provider == PE_O_AUTH_PROVIDER_APP,
              ask(Text.uiRemoveSignInAppAsk.text(["name": app.name]), title: Text.uiRemoveSignInApp.text,
                  yes: Text.uiRemove.text, no: Text.uiCancel.text, destructive: true) else { return }
        var error: UnsafeMutablePointer<CChar>?
        if !pe_sign_in_app_remove(core.handle, app.id, &error) {
            inform(Text.uiSignInAppNotRemoved.text(["reason": taken(error) ?? Text.uiUnknownReason.text]),
                   title: Text.uiRemoveSignInApp.text, style: .warning)
            return
        }
        fill(select: table.selectedRow)
    }

    func run() {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
    }
}
