// The Mac UI test of settings sync (step 45b of scripts/ui-e2e/SCENARIO.md): the Sync pane while off, Set Up Sync
// through a folder with a new passphrase, the pane while on, a second computer (another core in this process, as a
// computer that shares the folder) joining with the passphrase and getting the account, a contact it adds reaching
// this one on Sync Now, the Computers and History sheets, and Turn Off Sync.
import AppKit
import CInboxClassic

/// Another computer that syncs through the same folder: a core of its own, its passwords in memory, which answers
/// `SettingsSyncReady` as a window would
@MainActor
private final class SecondComputer {
    let core: Core
    let dir: URL
    var ready = false

    init?(dir: URL) {
        self.dir = dir
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        weak var me: SecondComputer?
        guard let core = Core(path: dir.appendingPathComponent("store.db").path, memoryPasswords: true, certificate: nil,
                              onEvent: { event in
                                  if event.kind == PE_EVENT_KIND_SETTINGS_SYNC_READY {
                                      MainActor.assumeIsolated { me?.ready = true }
                                  }
                              }) else { return nil }
        self.core = core
        me = self
    }

    /// sync turned on with `passphrase`: nil, or why not
    func turnOn(_ vault: URL, passphrase: String) -> String? {
        var error: UnsafeMutablePointer<CChar>?
        let on = SyncPlace(folder: vault.path).withC {
            pe_settings_sync_turn_on(core.handle, $0, $1, passphrase, "Laptop", pe_sync_choice_default(), &error)
        }
        let reason = taken(error)
        return on ? nil : reason ?? "refused"
    }
}

extension UITest {
    private static let syncPassphrase = "correct horse battery staple"

    /// whether `view` is there and shown
    private func shownNow(_ view: NSView?) -> Bool {
        view.map { !$0.isHiddenOrHasHiddenAncestor } ?? false
    }

    /// one whole sync of the second computer, as its window would answer it
    private func syncSecond(_ second: SecondComputer) async -> Bool {
        second.ready = false
        pe_settings_sync_now(second.core.handle)
        guard await waitUntil(30, { second.ready }) else { return false }
        pe_settings_sync_continue(second.core.handle, nil)
        return await waitUntil(30) { !second.core.syncState.busy }
    }

    func settingsSync() async throws {
        step("settings sync")
        let core = main.core
        let vault = FileManager.default.temporaryDirectory.appendingPathComponent("inbox-classic-vault-\(getpid())")
        try? FileManager.default.removeItem(at: vault)
        try? FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
        let devices = { (try? FileManager.default.contentsOfDirectory(atPath: vault.appendingPathComponent("devices").path))?.count ?? 0 }
        command(.options)
        guard let settings = await waitWindow("settings", 10), let shown = SettingsWindow.current else {
            check(false, "Settings opens")
            return
        }
        let paneBefore = shown.pane
        await showPane(shown, .sync)
        let setUp = shown.syncControl(.syncSetUp) as? NSButton
        check(shownNow(setUp) && !shownNow(shown.syncControl(.syncNow)) && !shownNow(shown.syncControl(.syncAccounts))
              && shownNow(find("settings.syncNote", in: settings)),
              "while sync is off, the Sync pane says what it is for and offers Set Up Sync, nothing else")
        await shot(settings, "sync-1-off")

        // Set Up Sync: a folder, then a new passphrase
        TestHooks.folder = { vault }
        defer { TestHooks.folder = nil }
        // Return opens it, as Set Up Sync is the pane's default button
        bringToFront(settings)
        pressKey(settings, 36)
        guard let setup = await waitWindow("sync.setup", 10) else {
            check(false, "Return opens Set Up Sync, the pane's default button (\(setUp?.keyEquivalent.debugDescription ?? "none"))")
            settings.close()
            return
        }
        check(setup.sheetParent === settings, "Return opens Set Up Sync, the pane's default button, as a sheet of Settings")
        let next: NSButton? = find("sync.next", in: setup)
        let folderKind: NSButton? = find("sync.kind.folder", in: setup)
        check(folderKind?.state == .on && next?.isEnabled == false,
              "it asks where to keep it, A folder chosen, Next off until a folder is chosen")
        await pause(0.3)
        await shot(setup, "sync-2-where")
        press(find("sync.chooseFolder", in: setup))
        check(await waitUntil(10) { next?.isEnabled == true }, "a folder chosen, Next is on")
        let path: NSTextField? = find("sync.folder", in: setup)
        check(path?.stringValue == vault.path, "the folder chosen is shown (\(path?.stringValue ?? ""))")
        // Return goes on, as Next is the step's default button
        bringToFront(setup)
        pressKey(setup, 36)
        let again = await waitFor(15) { () -> NSSecureTextField? in
            let field: NSSecureTextField? = find("sync.passphrase.field.1", in: setup)
            return shownNow(field) ? field : nil
        }
        check(again != nil, "Return is Next; the folder is empty: it asks for a new sync passphrase, twice")
        let name: NSTextField? = find("sync.name", in: setup)
        check(name?.stringValue.isEmpty == false, "the name of this computer is the system's (\(name?.stringValue ?? ""))")
        let what: NSButton? = find("sync.what.summary", in: setup)
        check(what?.title.hasSuffix(Text.uiSyncEverything.text) == true, "What to sync is folded, saying Everything (\(what?.title ?? ""))")
        let turnOn: NSButton? = find("sync.turnOn", in: setup)
        check(turnOn?.isEnabled == false, "Turn On Sync is off until a passphrase is typed")
        await pause(0.5)
        await shot(setup, "sync-3-start")
        type(Self.syncPassphrase, into: find("sync.passphrase.field.0", in: setup))
        type(Self.syncPassphrase, into: again)
        type("Desktop", into: name)
        check(turnOn?.isEnabled == true, "the same passphrase twice turns Turn On Sync on")
        press(turnOn)
        check(await waitUntil(20) { !setup.isVisible }, "Turn On Sync closes the sheet")
        let synced = await waitUntil(30) {
            let state = core.syncState
            return state.on && !state.busy && state.status.hasPrefix(lead(.syncStatusToday))
        }
        check(synced && FileManager.default.fileExists(atPath: vault.appendingPathComponent("vault.json").path) && devices() == 1,
              "the first sync writes the vault into the folder (\(core.syncState.status))")
        let status: NSTextField? = find("status.text", in: main.window)
        check(status?.stringValue == Text.uiSyncOn.text, "the status bar says sync is on (\(status?.stringValue ?? ""))")
        await pause(0.5)
        let place = (shown.syncControl(.syncPlace) as? NSTextField)?.stringValue ?? ""
        check(shown.syncShownOn && shownNow(shown.syncControl(.syncNow)) && shownNow(shown.syncControl(.syncAccounts))
              && !shownNow(setUp) && place.contains(vault.lastPathComponent) && place.contains("Desktop"),
              "while on, the pane shows where it syncs through and as what computer, how it went, its buttons and what it syncs (\(place))")
        let passwords = shown.syncControl(.syncPasswords) as? NSButton
        check((shown.syncControl(.syncAccounts) as? NSButton)?.state == .on && passwords?.state == .on && passwords?.isEnabled == true,
              "everything is synced, the secrets under their data")
        await shot(settings, "sync-4-on")

        // a second computer joins with the passphrase and gets the account
        let secondDir = FileManager.default.temporaryDirectory.appendingPathComponent("inbox-classic-second-\(getpid())")
        var second = SecondComputer(dir: secondDir)
        if let other = second {
            check(other.turnOn(vault, passphrase: "not it") != nil, "a wrong passphrase does not join")
            let refused = other.turnOn(vault, passphrase: Self.syncPassphrase)
            let joined = refused == nil ? await syncSecond(other) : false
            let accounts = other.core.accounts()
            check(joined && accounts.contains { $0.email == "testuser@inboxclassic.test" },
                  "the second computer joins and gets the account (\(accounts.count) accounts\(refused.map { ", \($0)" } ?? ""))")
            // a contact it adds reaches this one on Sync Now
            let added: Bool
            if case .success = other.core.saveBookCard(BookCard(name: "Sync Friend", addresses: ["friend@sync.example"])) {
                added = await syncSecond(other)
            } else {
                added = false
            }
            press(shown.syncControl(.syncNow) as? NSButton)
            let arrived = await waitUntil(30) { !core.bookCards("friend@sync.example").isEmpty }
            check(added && arrived, "a contact added on the second computer arrives on Sync Now")
        } else {
            check(false, "a second computer opens")
        }

        // the computers of the vault
        press(shown.syncControl(.syncComputers) as? NSButton)
        if let sheet = await waitWindow("sync.computers", 10) {
            let listed = await waitUntil(15) { SyncComputersSheet.current?.computers?.count == 2 }
            let computers = SyncComputersSheet.current?.computers ?? []
            check(listed && computers.first?.this == true && computers.contains { $0.name == "Laptop" },
                  "Computers lists both, this one first marked as this computer (\(computers.map(\.name)))")
            let remove: NSSegmentedControl? = find("sync.computers.remove", in: sheet)
            check(remove?.isEnabled(forSegment: 0) == false, "Remove is off until another computer is selected")
            await pause(0.3)
            await shot(sheet, "sync-5-computers")
            press(find("sync.computers.done", in: sheet))
            _ = await waitUntil(5) { !sheet.isVisible }
        } else {
            check(false, "Computers opens")
        }
        press(shown.syncControl(.syncHistory) as? NSButton)
        if let sheet = await waitWindow("sync.history", 10) {
            check(shownNow(find("sync.history.empty", in: sheet)), "History says no change was replaced")
            check(shownNow(find("sync.points.list", in: sheet)) && (find("sync.points.open", in: sheet) as NSButton?)?.isEnabled == false,
                  "and lists the restore points under them, Open off until one is selected")
            await pause(0.3)
            await shot(sheet, "sync-6-history")
            press(find("sync.history.done", in: sheet))
            _ = await waitUntil(5) { !sheet.isVisible }
        } else {
            check(false, "History opens")
        }

        // Turn Off Sync, asked first
        press(shown.syncControl(.syncTurnOff) as? NSButton)
        let asked = await waitWindow("alert", 10)
        let destructive = views(NSButton.self, in: asked?.contentView).first { $0.title == Text.uiSyncTurnOffButton.text }
        check(destructive?.hasDestructiveAction == true, "Turn Off Sync asks first, its button marked destructive")
        answer(asked, Text.uiSyncTurnOffButton.text)
        let off = await waitUntil(10) { !core.syncState.on }
        await pause(0.3)
        check(off && shownNow(setUp) && !shown.syncShownOn, "Turn Off Sync turns it off here, the pane offers Set Up Sync again")
        second = nil
        // the pane chosen last as it was, for the steps after this one
        await showPane(shown, paneBefore)
        settings.close()
        _ = await waitUntil { SettingsWindow.current == nil }
        try? FileManager.default.removeItem(at: vault)
        try? FileManager.default.removeItem(at: secondDir)
    }
}
