// The new account form, the password prompt, the browser sign-in and the Accounts window. The values go to the core
// as typed; the core checks them when it connects.
import AppKit
import CInboxClassic

@MainActor
private var securityNames: [String] { ["SSL/TLS", "STARTTLS", Text.uiSecurityNone.text] }

@MainActor
private func securityOf(_ name: String) -> PeSecurity {
    name == securityNames[1] ? PE_SECURITY_START_TLS : name == securityNames[2] ? PE_SECURITY_PLAIN : PE_SECURITY_TLS
}

@MainActor
private func securityName(_ security: PeSecurity) -> String {
    securityNames[security == PE_SECURITY_START_TLS ? 1 : security == PE_SECURITY_PLAIN ? 2 : 0]
}

/// the fields of the server form, in order
private enum Field: Int {
    case accountName, name, email, username, password, imapHost, imapPort, imapSecurity, smtpHost, smtpPort, smtpSecurity
}

private func validPort(_ text: String) -> Bool {
    guard text.count <= 5, let port = Int(text) else { return false }
    return (1...65535).contains(port)
}

@MainActor
private func validate(_ fields: [FormField]) -> String? {
    for required in [Field.email, .imapHost, .smtpHost] where fields[required.rawValue].value.isEmpty {
        let label = fields[required.rawValue].label
        return Text.uiFieldRequired.text(["field": label.hasSuffix(":") ? String(label.dropLast()) : label])
    }
    if !fields[Field.email.rawValue].value.contains("@") {
        return Text.uiEmailInvalid.text
    }
    if !validPort(fields[Field.imapPort.rawValue].value) || !validPort(fields[Field.smtpPort.rawValue].value) {
        return Text.uiPortsInvalid.text
    }
    return nil
}

/// the warning before a connection without encryption: true to go on
@MainActor
private func acceptPlain(_ fields: [FormField], title: String) -> Bool {
    let plain = securityOf(fields[Field.imapSecurity.rawValue].value) == PE_SECURITY_PLAIN
        || securityOf(fields[Field.smtpSecurity.rawValue].value) == PE_SECURITY_PLAIN
    return !plain || ask(Text.uiPlainWarning.text + "\n\n" + Text.uiContinueAsk.text, title: title, destructive: true)
}

/// the settings of the server form as the core takes them; `strings` keeps what they point to
@MainActor
private func settingsOf(_ fields: [FormField], _ strings: CStrings) -> PeAccountSettings {
    let value = { (field: Field) in fields[field.rawValue].value }
    // the user name is usually the address
    let username = value(.username).isEmpty ? value(.email) : value(.username)
    let name = value(.name).isEmpty ? value(.email) : value(.name)
    return PeAccountSettings(
        name: strings.add(name), email: strings.add(value(.email)), username: strings.add(username),
        imap_host: strings.add(value(.imapHost)), imap_port: UInt16(value(.imapPort)) ?? 993,
        imap_security: securityOf(value(.imapSecurity)), smtp_host: strings.add(value(.smtpHost)),
        smtp_port: UInt16(value(.smtpPort)) ?? 465, smtp_security: securityOf(value(.smtpSecurity)))
}

/// the server form's fields, filled in from what was found or stored
@MainActor
private func serverFields(accountName: String, name: String, email: String, username: String, imapHost: String, imapPort: UInt16,
                          imapSecurity: PeSecurity, smtpHost: String, smtpPort: UInt16, smtpSecurity: PeSecurity) -> [FormField] {
    [
        FormField(label: Text.uiFieldAccountName.text, value: accountName),
        FormField(label: Text.uiFieldName.text, value: name),
        FormField(label: Text.uiFieldEmail.text, value: email),
        FormField(label: Text.uiFieldUser.text, value: username),
        FormField(label: Text.uiFieldPassword.text, kind: .password),
        FormField(label: Text.uiFieldImapHost.text, value: imapHost),
        FormField(label: Text.uiFieldImapPort.text, value: "\(imapPort)", kind: .number),
        FormField(label: Text.uiFieldImapSecurity.text, value: securityName(imapSecurity), kind: .choice(securityNames)),
        FormField(label: Text.uiFieldSmtpHost.text, value: smtpHost),
        FormField(label: Text.uiFieldSmtpPort.text, value: "\(smtpPort)", kind: .number),
        FormField(label: Text.uiFieldSmtpSecurity.text, value: securityName(smtpSecurity), kind: .choice(securityNames)),
    ]
}

// ---- signing in through the browser ----

/// What a sign-in uses: a built-in client (Google, Microsoft) or the sign-in app `app`
struct SignInChoice {
    var provider: PeOAuthProvider = PE_O_AUTH_PROVIDER_NONE
    var app: Int64 = 0
}

@MainActor
enum SignIn {
    /// test runs (--sign-in-page-file): the sign-in page is written to this file for the test to open
    static var pageFile: String?

    /// signs in with `with` for `email` in the browser; the finished sign-in request, 0 when it did not work
    static func withBrowser(core: Core, with: SignInChoice, email: String) -> UInt64 {
        var page: UnsafeMutablePointer<CChar>?
        let request = email.withCString { pe_sign_in_begin(core.handle, with.provider, with.app, $0, &page) }
        // the core makes the page, and gives only an https page or one of a provider on this computer (a test server)
        let address = taken(page) ?? ""
        guard request != 0, !address.isEmpty else {
            inform(Text.uiSignInNotStarted.text, style: .error)
            return 0
        }
        if let pageFile {
            try? address.write(toFile: pageFile, atomically: true, encoding: .utf8)
        } else if let url = URL(string: address) {
            NSWorkspace.shared.open(url)
        }
        let text = email.isEmpty ? Text.uiSignInInBrowserYours.text : Text.uiSignInInBrowser.text(["account": email])
        guard Waiting.wait(for: request, text: text, title: Text.uiAddAccountTitle.text,
                           cancel: { pe_sign_in_cancel(core.handle, $0) })
        else { return 0 }
        var why: UnsafeMutablePointer<CChar>?
        if !pe_sign_in_result(core.handle, request, &why) {
            inform(Text.uiSignInFailed.text(["reason": taken(why) ?? Text.uiUnknownReason.text]), style: .warning)
            return 0
        }
        // back in front, the browser had it
        NSApp.activate()
        return request
    }
}

/// The sign-in apps as the core has them now: which built-in clients are on, and the added apps
struct SignInApps {
    struct App {
        let provider: PeOAuthProvider
        let id: Int64
        let name: String
        let issuer: String
        let enabled: Bool
        let usedBy: String
        let offReason: String
        let clientId: String
        let hasSecret: Bool
        let scopes: String
        let imapHost: String
        let imapPort: UInt16
        let imapSecurity: PeSecurity
        let smtpHost: String
        let smtpPort: UInt16
        let smtpSecurity: PeSecurity
    }

    let apps: [App]

    init(core: Core) {
        guard let list = pe_sign_in_apps(core.handle) else {
            apps = []
            return
        }
        defer { pe_sign_in_app_list_free(list) }
        apps = (0..<pe_sign_in_app_list_count(list)).compactMap { index in
            guard let app = pe_sign_in_app_list_get(list, index)?.pointee else { return nil }
            return App(provider: app.provider, id: app.id, name: text(app.name), issuer: text(app.issuer), enabled: app.enabled,
                       usedBy: text(app.used_by), offReason: text(app.off_reason), clientId: text(app.client_id),
                       hasSecret: app.has_secret, scopes: text(app.scopes), imapHost: text(app.imap_host),
                       imapPort: app.imap_port, imapSecurity: app.imap_security, smtpHost: text(app.smtp_host),
                       smtpPort: app.smtp_port, smtpSecurity: app.smtp_security)
        }
    }

    func builtin(_ provider: PeOAuthProvider) -> App? {
        apps.first { $0.provider == provider }
    }

    func on(_ provider: PeOAuthProvider) -> Bool {
        builtin(provider)?.enabled ?? false
    }

    /// the added apps that are on, for new accounts
    var addedOn: [App] {
        apps.filter { $0.provider == PE_O_AUTH_PROVIDER_APP && $0.enabled }
    }
}

// ---- the first page: the providers' sign-in buttons, or the name and address of any other account ----

private struct SignInButton {
    let provider: PeOAuthProvider
    let picture: String
    let label: String
    let company: String
}

@MainActor
private var signInButtons: [SignInButton] {
    [
        SignInButton(provider: PE_O_AUTH_PROVIDER_GOOGLE, picture: "brands/google-sign-in.png",
                     label: Text.uiSignInWith.text(["provider": "Google"]), company: "Google"),
        SignInButton(provider: PE_O_AUTH_PROVIDER_MICROSOFT, picture: "brands/microsoft-sign-in.png",
                     label: Text.uiSignInWith.text(["provider": "Microsoft"]), company: "Microsoft"),
    ]
}

/// What a page of Add Mail Account offers: the intro, a sign-in button for each of `providers` (faded and turned off
/// when its client is off; left out when all are off), More sign-in options when `more`, then when `fields` the name
/// and address of any other account and `next` to go on with that
@MainActor
private struct StartOffer {
    var intro = ""
    var providers: [PeOAuthProvider] = []
    var more = false
    var fields = false
    var next = Text.macNext.text
}

private enum Start {
    case cancel, next, signIn(SignInChoice)
}

@MainActor
private final class StartPage: NSObject {
    let window: NSWindow
    private let core: Core
    private let apps: SignInApps
    private let nameField = NSTextField(string: "")
    private let emailField = NSTextField(string: "")
    private var moreButton: NSButton?
    private var result = Start.cancel
    private let offer: StartOffer

    init(core: Core, apps: SignInApps, offer: StartOffer, name: String, email: String) {
        self.core = core
        self.apps = apps
        self.offer = offer
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 300), styleMask: [.titled], backing: .buffered,
                          defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiAddAccountTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("account.start")
        super.init()
        nameField.stringValue = name
        emailField.stringValue = email
        nameField.setAccessibilityIdentifier("account.name")
        emailField.setAccessibilityIdentifier("account.email")
        nameField.placeholderString = Text.macNamePlaceholder.text
        emailField.placeholderString = "name@example.com"

        var rows: [NSView] = [wrappingLabel(offer.intro)]
        // the rows as wide as the buttons need, whose words are longer in some languages
        var width: CGFloat = 440
        // the buttons, side by side; none when every one of them is off
        let shown = signInButtons.filter { offer.providers.contains($0.provider) }
        if shown.contains(where: { apps.on($0.provider) }) {
            let buttons = NSStackView(views: shown.map(signInButton))
            buttons.alignment = .top
            buttons.spacing = 12
            rows.append(buttons)
            width = max(width, ceil(buttons.fittingSize.width))
        }
        if offer.more {
            let more = linkButton(Text.macMoreSignInOptions.text, action: #selector(chooseMore(_:)))
            more.setAccessibilityIdentifier("account.more")
            moreButton = more
            rows.append(more)
        }
        if offer.fields {
            let line = NSBox()
            line.boxType = .separator
            rows.append(line)
            rows.append(wrappingLabel(Text.uiOtherAccount.text))
            let grid = NSGridView(views: [[NSTextField(labelWithString: Text.uiFieldName.text), nameField],
                                          [NSTextField(labelWithString: Text.uiFieldEmail.text), emailField]])
            grid.column(at: 0).xPlacement = .trailing
            grid.column(at: 1).xPlacement = .fill
            grid.rowAlignment = .firstBaseline
            rows.append(grid)
            // the fields end at the right margin; longer labels make them narrower
            grid.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        let cancel = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        let next = NSButton(title: offer.next, target: self, action: #selector(nextClicked))
        next.setAccessibilityIdentifier("account.next")
        // the default where it goes on with what was typed; beside a provider's button, the other way only
        if offer.fields {
            next.keyEquivalent = "\r"
        }
        let buttons = buttonRow([cancel, next], help: "account-form")
        rows.append(buttons)

        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        for row in rows where row is NSBox || row === rows[0] {
            row.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        window.contentView = stack
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        window.setContentSize(NSSize(width: width + 40, height: stack.fittingSize.height))
        window.initialFirstResponder = offer.fields ? nameField : nil
    }

    private func linkButton(_ title: String, action: Selector) -> NSButton {
        let button = LinkButton(title: title, target: self, action: action)
        button.isBordered = false
        button.attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: NSColor.linkColor, .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])
        return button
    }

    /// a provider's sign-in button, its own picture unchanged; when its client is off, faded, with why under it
    private func signInButton(_ sign: SignInButton) -> NSView {
        let on = apps.on(sign.provider)
        let button = NSButton(title: "", target: self, action: #selector(signInClicked(_:)))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.image = Icons.localizedPicture(sign.picture).map { picture in
            let height: CGFloat = 40
            picture.size = NSSize(width: picture.size.width * height / max(picture.size.height, 1), height: height)
            return picture
        }
        button.tag = Int(sign.provider.rawValue)
        button.isEnabled = on
        button.alphaValue = on ? 1 : 0.4
        button.setAccessibilityLabel(sign.label)
        button.setAccessibilityIdentifier(sign.provider == PE_O_AUTH_PROVIDER_GOOGLE ? "account.google" : "account.microsoft")
        guard !on else { return button }
        let reason = Text.uiTurnedOff.text(["name": sign.label]) + " " + (apps.builtin(sign.provider)?.offReason ?? "")
        button.toolTip = reason
        button.setAccessibilityHelp(reason)
        let why = linkButton(Text.uiWhy.text, action: #selector(whyClicked(_:)))
        why.tag = Int(sign.provider.rawValue)
        // under the button and no wider than it, wrapped when the words of a language are longer
        let note = NSTextField(wrappingLabelWithString: Text.uiOffHere.text)
        note.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        note.textColor = .secondaryLabelColor
        let width = button.image?.size.width ?? 180
        note.preferredMaxLayoutWidth = width
        note.widthAnchor.constraint(lessThanOrEqualToConstant: width).isActive = true
        why.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        why.attributedTitle = NSAttributedString(string: why.title, attributes: [
            .foregroundColor: NSColor.linkColor, .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
        ])
        let column = NSStackView(views: [button, note, why])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 2
        return column
    }

    @objc private func signInClicked(_ sender: NSButton) {
        result = .signIn(SignInChoice(provider: PeOAuthProvider(rawValue: UInt32(sender.tag)), app: 0))
        NSApp.stopModal()
    }

    @objc private func whyClicked(_ sender: NSButton) {
        let provider = PeOAuthProvider(rawValue: UInt32(sender.tag))
        let label = signInButtons.first { $0.provider == provider }?.label ?? ""
        inform(Text.uiTurnedOff.text(["name": label]) + "\n\n" + (apps.builtin(provider)?.offReason ?? ""),
               title: Text.uiAddAccountTitle.text)
    }

    /// More sign-in options: a menu of the added sign-in apps that are on, and Add a sign-in app
    @objc private func chooseMore(_ sender: NSButton) {
        let menu = NSMenu()
        for app in apps.addedOn {
            let item = NSMenuItem(title: app.name, action: #selector(moreChosen(_:)), keyEquivalent: "")
            item.target = self
            item.tag = Int(app.id)
            menu.addItem(item)
        }
        if !apps.addedOn.isEmpty {
            menu.addItem(.separator())
        }
        let add = NSMenuItem(title: Text.macAddSignInApp.text, action: #selector(moreChosen(_:)), keyEquivalent: "")
        add.target = self
        add.tag = 0
        menu.addItem(add)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    @objc private func moreChosen(_ sender: NSMenuItem) {
        let app = sender.tag == 0 ? signInAppEditor(core: core, app: nil) : Int64(sender.tag)
        guard app != 0 else { return }
        result = .signIn(SignInChoice(provider: PE_O_AUTH_PROVIDER_APP, app: app))
        NSApp.stopModal()
    }

    @objc private func nextClicked() {
        // the page of another account wants an address to look up
        if offer.fields && !emailField.stringValue.contains("@") {
            inform(Text.uiTypeEmail.text, style: .warning)
            window.makeFirstResponder(emailField)
            return
        }
        result = .next
        NSApp.stopModal()
    }

    @objc private func cancelled() {
        result = .cancel
        NSApp.stopModal()
    }

    func run(name: inout String, email: inout String) -> Start {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        if offer.fields {
            name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
            email = emailField.stringValue.trimmingCharacters(in: .whitespaces)
        }
        return result
    }
}

// ---- the server settings ----

/// the first line of the server settings form: where the settings came from
@MainActor
private func foundIntro(_ info: PeAutoconfigInfo?) -> String {
    guard let info else { return Text.uiFoundNone.text }
    let change = " " + Text.uiFoundChange.text
    switch info.source {
    case PE_AUTOCONFIG_SOURCE_GUESS:
        return Text.uiFoundGuess.text
    case PE_AUTOCONFIG_SOURCE_MX:
        return Text.uiFoundMx.text + change
    case PE_AUTOCONFIG_SOURCE_SRV:
        return Text.uiFoundSrv.text + change
    case PE_AUTOCONFIG_SOURCE_AUTODISCOVER:
        return Text.uiFoundAutodiscover.text + change
    default:
        return Text.uiFoundOther.text + change
    }
}

/// a provider that does not take the account's password from mail programs: says so, and opens the page that tells
/// how to make an app password when the user wants it
@MainActor
private func explainAppPassword(_ info: PeAutoconfigInfo?) {
    guard let info, info.app_password_provider != nil else { return }
    let provider = text(info.app_password_provider)
    var said = info.app_password_warning != nil ? text(info.app_password_warning)
        : Text.uiAppPasswordNeeded.text(["provider": provider])
    let page = text(info.app_password_instructions)
    let linkable = page.hasPrefix("https://")
    if linkable {
        said += "\n\n" + Text.uiAppPasswordOpen.text(["provider": provider])
        if ask(said, title: Text.uiAddAccountTitle.text, style: .information) {
            openExternally(URL(string: page))
        }
    } else {
        inform(said, title: Text.uiAddAccountTitle.text)
    }
}

/// signs in in the browser and adds the account signed in to, named `name` or, without one, as at the provider
@MainActor
private func addSignedIn(core: Core, with: SignInChoice, name: String, email: String) -> Int64 {
    let request = SignIn.withBrowser(core: core, with: with, email: email)
    guard request != 0 else { return 0 }
    let account = name.withCString { pe_account_add_signed_in(core.handle, request, $0) }
    if account <= 0 {
        inform(Text.uiAccountNotSaved.text, title: Text.uiAddAccountTitle.text, style: .error)
    }
    return account
}

/// asks for a new account and adds it to the core; its id, or 0 when cancelled
@MainActor
func newAccountDialog(core: Core) -> Int64 {
    var name = ""
    var email = ""
    let apps = SignInApps(core: core)
    var first = StartOffer()
    first.providers = [PE_O_AUTH_PROVIDER_GOOGLE, PE_O_AUTH_PROVIDER_MICROSOFT]
    first.more = true
    first.fields = true
    first.intro = apps.on(PE_O_AUTH_PROVIDER_GOOGLE) || apps.on(PE_O_AUTH_PROVIDER_MICROSOFT)
        ? Text.uiStartIntro.text : Text.uiStartIntroApps.text
    switch StartPage(core: core, apps: apps, offer: first, name: name, email: email).run(name: &name, email: &email) {
    case .cancel: return 0
    case .signIn(let with): return addSignedIn(core: core, with: with, name: name, email: email)
    case .next: break
    }

    // the servers of the address, looked up
    let request = email.withCString { pe_autoconfig_start(core.handle, $0, nil) }
    let domain = email.split(separator: "@").last.map(String.init) ?? email
    guard Waiting.wait(for: request, text: Text.macLookingUp.text(["domain": domain]), title: Text.uiAddAccountTitle.text,
                       cancel: { pe_autoconfig_cancel(core.handle, $0) }) else { return 0 }
    let found = pe_autoconfig_result(core.handle, request)
    defer { if let found { pe_autoconfig_free(found) } }
    let info = found.flatMap { pe_autoconfig_info($0)?.pointee }

    // an address at Google or Microsoft: a browser sign-in first, an app password the other way
    let provider = info.map { info in pe_oauth_provider_for(core.handle, info.imap_host) } ?? PE_O_AUTH_PROVIDER_NONE
    var offer = StartOffer()
    offer.more = !apps.addedOn.isEmpty
    offer.next = Text.uiUseAppPassword.text
    if provider != PE_O_AUTH_PROVIDER_NONE && (apps.on(provider) || offer.more) {
        let company = signInButtons.first { $0.provider == provider }?.company ?? Text.uiTheProvider.text
        if apps.on(provider) {
            offer.providers = [provider]
            offer.intro = Text.uiProviderIntro.text(["email": email, "provider": company])
        } else {
            offer.intro = Text.uiProviderIntroApps.text(["email": email, "provider": company])
        }
        switch StartPage(core: core, apps: apps, offer: offer, name: name, email: email).run(name: &name, email: &email) {
        case .cancel: return 0
        case .signIn(let with): return addSignedIn(core: core, with: with, name: name, email: email)
        case .next: break
        }
    }

    explainAppPassword(info)
    var fields = serverFields(
        accountName: taken(email.withCString { pe_default_account_name($0) }) ?? "", name: name, email: email, username: info.map { text($0.username) } ?? "", imapHost: info.map { text($0.imap_host) } ?? "",
        imapPort: info?.imap_port ?? 993, imapSecurity: info?.imap_security ?? PE_SECURITY_TLS,
        smtpHost: info.map { text($0.smtp_host) } ?? "", smtpPort: info?.smtp_port ?? 465,
        smtpSecurity: info?.smtp_security ?? PE_SECURITY_TLS)
    // the name and address were typed already: the password is next
    while let filled = formDialog(title: Text.uiAddAccountTitle.text, intro: foundIntro(info), fields: fields,
                                  ok: Text.uiFinish.text, focus: Field.password.rawValue, help: "account-form",
                                  validate: validate) {
        fields = filled
        guard acceptPlain(fields, title: Text.uiAddAccountTitle.text) else { continue }
        let strings = CStrings()
        var settings = settingsOf(fields, strings)
        let password = strings.add(fields[Field.password.rawValue].value)
        let account = pe_account_add(core.handle, &settings, password)
        strings.wipe()
        if account > 0 {
            setAccountName(core: core, account: account, fields[Field.accountName.rawValue].value)
            return account
        }
        inform(Text.uiAccountNotSaved.text, title: Text.uiAddAccountTitle.text, style: .error)
    }
    return 0
}

/// the password of `account`, asked for; nil when cancelled
@MainActor
func passwordDialog(account: String) -> String? {
    formDialog(title: Text.uiLogon.text, intro: Text.uiEnterPassword.text(["account": account]),
               fields: [FormField(label: Text.uiFieldPassword.text, kind: .password)])?[0].value
}

// ---- the Accounts window ----

/// the account's own name for the folder list, as typed in its form
@MainActor
private func setAccountName(core: Core, account: Int64, _ name: String) {
    _ = name.trimmingCharacters(in: .whitespaces).withCString { pe_account_set_name(core.handle, account, $0) }
}

/// the other addresses of Properties saved, or why not said
@MainActor
private func saveOtherAddresses(core: Core, account: Int64, _ text: String) -> Bool {
    var reason: UnsafeMutablePointer<CChar>?
    guard !text.withCString({ pe_set_account_addresses(core.handle, account, $0, &reason) }) else { return true }
    inform(taken(reason) ?? Text.uiAccountNotSaved.text, title: Text.uiProperties.text, style: .warning)
    return false
}

/// the Properties of `account`, from File > Accounts or the account's menu in the folder tree; true when it changed
@MainActor
func accountProperties(core: Core, account: Int64) -> Bool {
    guard let info = core.accounts().first(where: { $0.id == account }) else { return false }
    return accountProperties(core: core, account: account, accountName: info.accountName,
                             signsInWith: info.oauth != PE_O_AUTH_PROVIDER_NONE ? info.signsInWith : "")
}

/// the settings of an account, changed: the server form for a password account, the name for one that signs in
/// through the browser (its servers are the sign-in's); a password typed in replaces the kept one
@MainActor
private func accountProperties(core: Core, account: Int64, accountName: String, signsInWith: String) -> Bool {
    guard let view = pe_account_settings(core.handle, account) else { return false }
    defer { pe_account_settings_free(view) }
    guard let stored = pe_account_settings_info(view)?.pointee else { return false }
    var fields = serverFields(accountName: accountName, name: text(stored.name), email: text(stored.email), username: text(stored.username),
                              imapHost: text(stored.imap_host), imapPort: stored.imap_port, imapSecurity: stored.imap_security,
                              smtpHost: text(stored.smtp_host), smtpPort: stored.smtp_port, smtpSecurity: stored.smtp_security)
    // last, the other addresses it sends from
    let others = FormField(label: Text.uiFieldOtherAddresses.text, value: taken(pe_account_addresses(core.handle, account)) ?? "")
    fields.append(others)
    if !signsInWith.isEmpty {
        // a browser sign-in account: the names and the other addresses only, the rest is the provider's
        var shown = [fields[Field.accountName.rawValue], fields[Field.name.rawValue], others]
        while let names = formDialog(title: Text.uiProperties.text, intro: Text.uiSignsInWith.text(["app": signsInWith]),
                                     fields: shown, help: "account-properties") {
            shown = names
            guard saveOtherAddresses(core: core, account: account, names[2].value) else { continue }
            fields[Field.accountName.rawValue] = names[0]
            fields[Field.name.rawValue] = names[1]
            let strings = CStrings()
            var settings = settingsOf(fields, strings)
            guard pe_account_update(core.handle, account, &settings) else { return false }
            setAccountName(core: core, account: account, names[0].value)
            return true
        }
        return false
    }
    let was = (imap: stored.imap_security, imapHost: text(stored.imap_host), smtp: stored.smtp_security, smtpHost: text(stored.smtp_host))
    while let filled = formDialog(title: Text.uiProperties.text, intro: Text.uiKeepPassword.text, fields: fields,
                                  help: "account-properties", validate: validate) {
        fields = filled
        // warned for a side without encryption, unless it was so already to the same server
        let newlyPlain = { (security: Field, host: Field, before: PeSecurity, beforeHost: String) in
            securityOf(fields[security.rawValue].value) == PE_SECURITY_PLAIN
                && (before != PE_SECURITY_PLAIN || fields[host.rawValue].value != beforeHost)
        }
        let warn = newlyPlain(.imapSecurity, .imapHost, was.imap, was.imapHost) || newlyPlain(.smtpSecurity, .smtpHost, was.smtp, was.smtpHost)
        if warn && !acceptPlain(fields, title: Text.uiProperties.text) {
            continue
        }
        guard saveOtherAddresses(core: core, account: account, fields[fields.count - 1].value) else { continue }
        let strings = CStrings()
        var settings = settingsOf(fields, strings)
        guard pe_account_update(core.handle, account, &settings) else {
            inform(Text.uiAccountNotSaved.text, title: Text.uiProperties.text, style: .error)
            continue
        }
        setAccountName(core: core, account: account, fields[Field.accountName.rawValue].value)
        let password = fields[Field.password.rawValue].value
        if !password.isEmpty {
            pe_account_set_password(core.handle, account, strings.add(password))
            strings.wipe()
        }
        return true
    }
    return false
}

/// File > Accounts: the accounts listed, to add, change (Properties), sign (Signature) or remove; true when one changed
@MainActor
func accountsDialog(core: Core) -> Bool {
    let dialog = AccountsWindow(core: core)
    return dialog.run()
}

@MainActor
private final class AccountsWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let window: NSWindow
    private let core: Core
    private let table = NSTableView()
    private var accounts: [Account] = []
    private var changed = false

    init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 280), styleMask: [.titled, .resizable],
                          backing: .buffered, defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiAccountsTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("accounts")
        super.init()
        for (id, title, width) in [("name", Text.uiColAccount.text, 140.0), ("email", Text.uiColEmail.text, 190.0),
                                   ("server", Text.uiColIncoming.text, 160.0)] {
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
        table.doubleAction = #selector(properties)
        table.setAccessibilityIdentifier("accounts.list")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let buttons = NSStackView(views: [
            button(Text.macAddButton.text, #selector(add), "accounts.add"),
            button(Text.macPropertiesButton.text, #selector(properties), "accounts.properties"),
            button(Text.macSignatureButton.text, #selector(signature), "accounts.signature"),
            button(Text.uiRemove.text, #selector(remove), "accounts.remove"),
            button(Text.macSignInAppsButton.text, #selector(signInApps), "accounts.apps"),
        ])
        buttons.orientation = .vertical
        buttons.alignment = .leading
        let close = button(Text.uiClose.text, #selector(closeClicked), "accounts.close")
        close.keyEquivalent = "\r"
        // the help button over Close, at the bottom of the column
        let side = NSStackView(views: [buttons, NSView(), HelpButton("account-properties"), close])
        side.orientation = .vertical
        side.alignment = .leading
        for view in buttons.arrangedSubviews + [close] {
            view.widthAnchor.constraint(equalToConstant: 130).isActive = true
        }
        let stack = NSStackView(views: [scroll, side])
        stack.alignment = .top
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        scroll.heightAnchor.constraint(equalTo: stack.heightAnchor, constant: -32).isActive = true
        side.heightAnchor.constraint(equalTo: scroll.heightAnchor).isActive = true
        window.contentView = stack
        fill()
    }

    private func button(_ title: String, _ action: Selector, _ id: String) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.setAccessibilityIdentifier(id)
        return button
    }

    /// a row per account: its name, address and incoming server (or the provider's sign-in); `select` stays selected
    private func fill(select: Int = 0) {
        accounts = core.accounts()
        table.reloadData()
        if !accounts.isEmpty {
            table.selectRowIndexes(IndexSet(integer: min(select, accounts.count - 1)), byExtendingSelection: false)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { accounts.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let account = accounts[row]
        let value: String
        switch column?.identifier.rawValue {
        case "name": value = account.title
        case "email": value = account.email
        default: value = account.oauth != PE_O_AUTH_PROVIDER_NONE ? Text.uiBrowserSignInServer.text(["server": account.imapHost])
                                                                  : account.imapHost
        }
        return listCell(tableView, value)
    }

    private var selected: Account? {
        accounts.indices.contains(table.selectedRow) ? accounts[table.selectedRow] : nil
    }

    @objc private func add() {
        if newAccountDialog(core: core) > 0 {
            changed = true
            fill(select: accounts.count)
        }
    }

    @objc private func properties() {
        guard let account = selected else { return }
        if accountProperties(core: core, account: account.id) {
            changed = true
            fill(select: table.selectedRow)
        }
    }

    @objc private func signature() {
        guard let account = selected else { return }
        SignatureEditor.edit(core: core, account: account.id, name: account.name)
    }

    @objc private func remove() {
        guard let account = selected,
              ask(Text.uiRemoveAccountAsk.text, title: Text.uiRemoveAccount.text, yes: Text.uiRemove.text,
                  no: Text.uiCancel.text, destructive: true) else { return }
        let row = table.selectedRow
        pe_account_remove(core.handle, account.id)
        changed = true
        fill(select: row)
    }

    @objc private func signInApps() {
        signInAppsDialog(core: core)
        fill(select: table.selectedRow)
    }

    @objc private func closeClicked() {
        NSApp.stopModal()
    }

    func run() -> Bool {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        return changed
    }
}

/// a borderless link button whose text lines up with the labels: its cell draws the title 2pt in
private final class LinkButton: NSButton {
    override var alignmentRectInsets: NSEdgeInsets { NSEdgeInsets(top: 0, left: 2, bottom: 0, right: 0) }
}
