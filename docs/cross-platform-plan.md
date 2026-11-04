# Inbox Classic on macOS and Linux

A plan for a Mac version and a Linux version of Inbox Classic, written 2026-11-04 against version 0.4.1, with the decisions below confirmed the same day. The overview page `docs/cross-platform-overview.html` summarizes it.

The short version: the Rust core (47,600 lines in `core/`, everything that touches mail data) already builds and passes its tests on macOS and Linux in CI. What a new platform needs is a new shell of about the size of the Windows one (`app/`, 8,600 lines of C++), a password backend for that platform in the core, and a build, test and release path. Each shell is native: Swift and AppKit on the Mac, Rust and GTK 4 on Linux, nothing shared between the three beyond the core. The last part of the plan is how three shells stay in step once all three exist.

## Decisions, confirmed 2026-11-04

1. **Native look on the Mac and on Linux.** The Outlook Express look comes almost free from the classic Win32 controls; AppKit and GTK would have to fake it, and that is the opposite of using native elements. On the Mac and on Linux the app is a standard three-pane mail client with the same layout, features, icons and words, sold on what the core does (the security model, the search, the folding, offline mail), not on the retro look. On Linux that means a libadwaita header bar, not a classic menu bar.
2. **Current releases only, Apple silicon only.** macOS 27 (released 2026-09-14, Apple silicon only) built with Xcode 27; the deployment target starts at macOS 26 because this Mac runs 26.6.2, and moves to 27 when the Mac does. arm64 only, no universal binary, no Intel Macs. Ubuntu 26.04 LTS and newer (26.10 is out), GNOME on Wayland, x86_64 and arm64.
3. **Three shells, one core.** `app/` (Windows, C++) stays as it is, name included. `mac/` is Swift on the C ABI of `pe-ffi`. `linux/` is Rust with gtk4-rs on `pe-core` directly (the best supported GTK binding, all safe Rust, no fourth language; the C ABI is for the languages that need it). `pe-ffi` keeps its one-export-per-core-method shape so the three shells call the same operations by the same names.
4. **The core gets thicker, the shells thinner.** Anything the C++ computes from mail data today moves into the core before the new shells start, so it is written once (section Phase 0).
5. **Linux ships as a `.deb` first,** then a Flatpak on Flathub for other distributions and for updates. No snap.
6. **Distribution and updates.** The Mac: Developer ID signing and notarization, a DMG, in-app updates through Sparkle; no Mac App Store, so no App Sandbox. Linux: the `.deb` from the release page, Flatpak's own updates, a signed apt repository later. Windows keeps the installer.
7. **Every release is built from the release Mac,** as today: Windows on the build machine, the Mac here, Linux in Docker here; signed here, one `hashes.txt`, published only when every platform's package exists (section Releasing on three platforms). No signing keys on GitHub.
8. **The homepage detects the visitor's platform and shows all three:** the visitor's download first, the other two under it, screenshots from that platform's own end-to-end run (section The homepage).
9. **One developer, the Mac first,** then Linux; about six months to the first release on all three.
10. **The Linux tray depends on Ubuntu's AppIndicator extension** (on by default in Ubuntu's GNOME). Where it is absent the app has no tray and closing the last window quits, which is what GNOME expects.

## What is shared and what is not

| Part                                                                                                       | Windows                              | macOS                                          | Linux                                  |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------- | -------------------------------------- |
| IMAP, SMTP, MIME, sanitizing, store, search, sync, autoconfig, OAuth, content folding, calendar, BIMI, eml | `core/` unchanged                    | same                                           | same                                   |
| TLS                                                                                                        | rustls, platform verifier (Schannel) | rustls, platform verifier (Security.framework) | rustls, platform verifier (system CAs) |
| Passwords                                                                                                  | Credential Manager (`secrets.rs`)    | Keychain (new backend)                         | Secret Service, GNOME Keyring (new)    |
| The C ABI and header                                                                                       | `pe-ffi`, `inbox_classic.h`          | same, through a Swift module map               | not used, `pe-core` linked as Rust     |
| The sanitized documents, the CSP, `editor.js`                                                              | `pe-html`                            | same                                           | same                                   |
| The blocking policy of the web views                                                                       | `WebResourceRequested` filter in C++ | content rules from the core (new, Phase 0)     | same rules                             |
| Windows, dialogs, menus, lists                                                                             | Win32 (`app/`)                       | AppKit (`mac/`)                                | GTK 4 and libadwaita (`linux/`)        |
| Web views                                                                                                  | WebView2                             | WKWebView                                      | WebKitGTK 6.0                          |
| Help                                                                                                       | `help.html` as an exe resource       | the same file, a bundle resource               | the same file, a gresource             |
| Icons                                                                                                      | Fluent SVGs as bitmap strips         | the same SVGs as template images               | the same SVGs as symbolic icons        |
| UI end-to-end test                                                                                         | PowerShell and UI Automation         | XCUITest                                       | dogtail (AT-SPI) under Xvfb            |
| Package                                                                                                    | NSIS installer, Azure signing        | signed and notarized app in a DMG, Sparkle     | `.deb` (cargo-deb), Flatpak            |

The version stays the `[workspace.package] version` of `core/Cargo.toml`, release-please stays as it is, and `scripts/release.sh` grows to produce every platform's package and one `hashes.txt` (section Releasing on three platforms).

## Phase 0: the core and the shared pieces (2 weeks)

Done before either shell starts, so both start from the same base. Everything here is testable with `cargo test` on this Mac.

1. **Password backends** in `pe-core/src/secrets.rs`, on the `keyring-core` trait the Windows backend already uses: `apple-native-keyring-store` 1.0 (the login keychain; service `InboxClassic`, account `<profile>/<account>` as today) under `cfg(target_os = "macos")`, and `zbus-secret-service-keyring-store` 1.0 (the Secret Service over D-Bus, which is GNOME Keyring on Ubuntu) under `cfg(target_os = "linux")`. When no Secret Service answers (a container, a bare session), `unavailable` carries the reason exactly as the Windows backend does when the Credential Manager fails, and the app says passwords are kept for this run only. The tests keep `PasswordStore::Memory`. A Keychain item is readable without a prompt by the app that created it, which means the same code signing identity: dev builds are signed with the Developer ID certificate too (Xcode's Debug configuration with the team set), or run with `--memory-passwords`.
2. **Presentation code out of C++.** `FormatSize` (`ui.cpp`) becomes `pe_format_size`; the same for any other string the C++ composes from mail data (grep `ui.cpp` and `mailbox.cpp` for `L"` next to core values). Dates stay with each platform's locale formatter (`GetDateFormatEx`, `DateFormatter`, `glib::DateTime::format`).
3. **The blocking policy once, in Rust.** `pe-html` gains `pe_webkit_content_rules(allow_remote_images)`: the WebKit content-rule JSON that blocks every load, lets the app's own scheme through, and when remote pictures are allowed lets `http(s)` images through and nothing else. Both WebKit shells compile it (`WKContentRuleListStore`, `WebKitUserContentFilterStore`); Rust tests pin it. The documents name no origin (the CSP is `default-src 'none'` with explicit sources), so nothing else changes: Windows keeps serving them at `https://preview.inboxclassic.invalid/`, and the WebKit shells, which cannot intercept `https`, serve the same documents from a custom scheme, `inboxclassic://preview/<n>` and `inboxclassic://compose/`, with `cid:` parts through a `cid` scheme handler.
4. **`editor.js` on WebKit.** The page posts its plain strings through `window.chrome.webview` today; it also posts through `window.webkit.messageHandlers.host` (the same API in WKWebView and WebKitGTK). File drops stay Windows-only in the page (`postMessageWithAdditionalObjects`): on WebKit the shell takes file drops before the web view sees them and feeds them to the same Insert Picture and attach paths. The host already drives the page through six named functions (`pe.exec`, `pe.link`, `pe.signature`, `pe.send`, `pe.clean`, `pe.focus`), so every shell runs the same six strings; `editor.rs` documents them as the contract.
5. **One help for three platforms.** `help.html` says Ctrl 34 times and names Windows, the taskbar, Explorer, the Credential Manager and the notification area. Platform-only passages get `data-os="windows|mac|linux"`, keys get `<kbd data-key="mod">`, and `pe_help_page(platform)` in `pe-html` returns the page for one platform. One source, filtered in Rust.
6. **The command table.** `core/commands.toml` lists every user command (31 today, the `IDM_*` ids of `app.h`): id, menu, label, the shortcut on each platform, toolbar icon, help anchor, and what it needs (a message, a folder, an account, nothing). `pe-ffi`'s `build.rs`, which already writes the C header, also writes `core/include/commands.h` (C enum and table), `mac/Sources/Generated/Commands.swift` (a Swift enum) and `linux/src/generated/commands.rs`, all committed and checked in CI like the header. A shell handles commands in one exhaustive `switch`, so a command added to the table without a handler fails that shell's build. The control ids the e2e drivers look for come from a `[controls]` table in the same file. Windows migrates its `IDM_*` constants to the generated header as part of this.
7. **The link line for the Mac.** `cargo rustc -p pe-ffi --release -- --print native-static-libs` on this Mac gives the frameworks `libpe_ffi.a` needs (Security, CoreFoundation, SystemConfiguration for the platform verifier); it goes into `mac/project.yml`. `core/.cargo/config.toml` only sets flags for the MSVC target, so nothing changes there.
8. **Layout.** `app/` stays. `mac/` and `linux/` are added beside it, `docs/` holds this plan.
9. **`--version` on every shell:** prints the version and exits, on Windows too. The release process starts each package once with it as its boot test, the way `cut-release` boot-tests the EmailEngine binaries.

## Phase 1: macOS (10 to 12 weeks)

### Setting up this Mac

The machine: macOS 26.6.2 on an M5 Pro, Swift 6.4 from the Command Line Tools, rustup with `aarch64-apple-darwin`, QEMU and Docker (OrbStack) from Homebrew, and the Developer ID Application certificates of Postal Systems OÜ in the keychain. Missing: Xcode itself, needed for XCUITest and for `xcodebuild`.

```
brew install xcodesorg/made/xcodes      # Xcode downloads from the command line
xcodes install 27 --select              # Xcode 27 needs macOS 26.6 or newer, which this Mac has; about 15 GB
sudo xcodebuild -license accept && xcodebuild -runFirstLaunch
brew install xcodegen create-dmg        # the Xcode project from project.yml; the DMG
xcrun notarytool store-credentials inbox-classic --key AuthKey.p8 --key-id ... --issuer ...   # an App Store Connect API key, once
```

### Layout

```
mac/
  project.yml                 xcodegen: the app target, the UI test target, the Sparkle package
  Info.plist, InboxClassic.entitlements (hardened runtime, no App Sandbox)
  Core/module.modulemap       imports ../../core/include/inbox_classic.h as a Swift module
  Sources/
    App.swift                 NSApplicationDelegate, the menu bar from the command table, mailto: and .eml opening
    Core.swift                the C API in Swift: handles as classes freed in deinit, strings copied and released
                              with pe_string_free, the event callback copied onto DispatchQueue.main
    MainWindow.swift          NSSplitViewController with the folder outline, the message table and the reading pane,
                              NSToolbar with the Fluent icons as template images, NSSearchField
    Folders.swift             NSOutlineView, source-list style, drop target for messages
    Messages.swift            NSTableView, view-based, its data source paging through pe_message_list like the
                              virtual list view does
    Preview.swift             WKWebView locked down (below), the header with attachments, logo, calendar, unsubscribe
    Editor.swift              the one WKWebView with a script: the editor page, the "host" message handler
    Compose.swift             address fields with the completion popover (Complete.swift), the format bar, attachments
    Accounts.swift            the two-step account form and the password prompt, the Google and Microsoft buttons
    SignInApps.swift, Outbox.swift, Help.swift, Print.swift
    Notifications.swift       the Dock badge, UNUserNotificationCenter, the optional status item
    Generated/Commands.swift  from core/commands.toml
  UITests/                    XCUITest driver of the shared scenario
```

`xcodegen generate` writes `mac/InboxClassic.xcodeproj` (ignored by git); `project.yml` is what is reviewed. The Rust library is built by `scripts/mac-build.sh` before `xcodebuild` (and by a run-script phase for builds started from Xcode), into `build/cargo/aarch64-apple-darwin/release/libpe_ffi.a`.

### Week 1: the web view spike, go or no-go

The security model is only as good as what WKWebView lets us refuse, so this is built and tested before anything else:

- A `WKWebViewConfiguration` with `defaultWebpagePreferences.allowsContentJavaScript = false`, `websiteDataStore = .nonPersistent()`, `preferences.javaScriptCanOpenWindowsAutomatically = false`, the `inboxclassic` and `cid` schemes on a `WKURLSchemeHandler` that serves the core's document and attachment bytes from memory.
- The content rule list from Phase 0, added to the `WKUserContentController`; when the user allows the pictures of a message, the "allow http(s) images" list replaces it for that message and the page is loaded again.
- `WKNavigationDelegate` cancels every navigation but the document's own and opens `http(s)` and `mailto:` links with `NSWorkspace.shared.open`; `WKUIDelegate` returns nil for new windows.
- A hostile test message, kept in the repo for all three shells: scripts, remote `img`, `srcset`, CSS `url()`, `@import`, fonts, `iframe`, `object`, `embed`, `video poster`, `meta refresh`, a form, `javascript:` and `data:` links, `target=_blank`, SVG `use`. A local HTTP server counts requests; the expected count is zero, and the e2e scenario "pictures from the internet" keeps checking it on every platform.

WebKit's web content runs in its own sandboxed process on both WebKit platforms, one layer the Windows build does not have. If something cannot be refused, the fallback is the editor's approach: `pe-html` strips that construct for the WebKit document variant.

### The windows, in order

| Windows (`app/src`)                  | Mac                                                                                                                                                                  | Notes                                                                                                  |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `main.cpp` frame, splitters, menus   | `NSWindow`, `NSSplitViewController` (autosaved), the menu bar from the command table with ⌘ shortcuts                                                                | The app menu, Window and Help menus are Mac additions; Quit is ⌘Q, closing the window keeps it running |
| `mailbox.cpp` folder tree            | `NSOutlineView`, source list, unread counts                                                                                                                          | Drag destination for messages (a custom pasteboard type carrying message ids)                          |
| `mailbox.cpp` message list           | `NSTableView`, view-based, sortable column headers                                                                                                                   | Paged from the core as the owner-data list view is                                                     |
| `mailbox.cpp` reading pane           | A header view and `Preview.swift`                                                                                                                                    | Attachment menu, Save (NSSavePanel, Downloads by default), Mark, Flag, Junk, Move, Properties          |
| `accounts.cpp`                       | A window with the two steps; the Google and Microsoft buttons from `app/res/brands`                                                                                  | Sign-in opens the browser; `--sign-in-page-file` kept for the test                                     |
| `compose.cpp`, `complete.cpp`        | A window; `NSTextField`s with a completion `NSPopover` that never takes focus; `NSSegmentedControl` format bar                                                       | File drops handled on the window's content view, never by the web view                                 |
| `editor.cpp`                         | `Editor.swift`                                                                                                                                                       | Same page, same six functions, the "host" message handler                                              |
| `outbox.cpp`, `signinapps.cpp`       | Windows with an `NSTableView`                                                                                                                                        |                                                                                                        |
| `help.cpp`                           | A window with a scripts-off WKWebView showing `pe_help_page("mac")`                                                                                                  | Help menu; ⌘? opens it                                                                                 |
| `print.cpp`                          | `WKWebView.printOperation(with:)` run as an `NSPrintOperation` with the panel                                                                                        | The system panel has the preview; `pe_print_page` and its script are Windows-only                      |
| `tray.cpp`                           | `NSApp.dockTile.badgeLabel` for the unread count, `UNUserNotificationCenter` for new mail, an `NSStatusItem` as a preference                                         | A click on the notification opens the message                                                          |
| `ui.cpp` preferences in the registry | `UserDefaults`                                                                                                                                                       |                                                                                                        |
| `main.cpp` default app, mailto, .eml | `CFBundleURLTypes` (mailto), `CFBundleDocumentTypes` (`public.email-message`), `NSWorkspace.setDefaultApplication(at:toOpenURLsWithScheme:)`, `application(_:open:)` | Single instance is free on the Mac                                                                     |
| `main.cpp` command line              | `--store`, `--memory-passwords`, `--pin-certificate`, `--sign-in-page-file`, unchanged                                                                               | The e2e relies on them; the store is `~/Library/Application Support/Inbox Classic` otherwise           |

Address completion could be `NSTokenField`; the plain-field-plus-popover design of `complete.cpp` is kept so the three shells behave the same.

### Packaging and updates

- `scripts/mac-build.sh`: `cargo build --release --locked -p pe-ffi` (in `core/`, target dir `build/cargo`), `xcodegen generate`, `xcodebuild -configuration Release` into `build/mac/`.
- `scripts/mac-package.sh`: sign Sparkle's XPC services and framework, then the app with `codesign --options runtime --timestamp` and the Developer ID Application certificate of Postal Systems OÜ, `notarytool submit --wait`, `stapler staple`, `create-dmg` with the Applications arrow, sign and notarize the DMG too. The file is `InboxClassic.dmg` without a version so `releases/latest/download/InboxClassic.dmg` is the homepage's link.
- Sparkle 2.10: `generate_keys` once on the release Mac (the EdDSA key stays in its keychain), `SUFeedURL` `https://inboxclassic.com/appcast.xml` and `SUPublicEDKey` in `Info.plist`, `generate_appcast` in `release.sh`, the appcast committed to `../inboxclassic.com` (GitHub Pages).
- `scripts/release.sh` runs `mac-package.sh` after the Windows installer, adds the DMG to `hashes.txt` and pushes the appcast after publishing (section Releasing on three platforms).
- `scripts/mac-run.sh`, `scripts/mac-screenshot.sh` (`screencapture -l <window id>`; needs Screen Recording for the terminal, once), `scripts/mac-ui-e2e.sh`.

### The UI end-to-end test and CI

- `mac/UITests` is an XCUITest target: `XCUIApplication()` launched with the same flags as on Windows, controls found by `accessibilityIdentifier`s from the `[controls]` table, screenshots of each window saved under the same names as `ui-e2e.ps1` writes, checks over ImapKit's REST API with `URLSession`. `scripts/mac-ui-e2e.sh` starts ImapKit (`core/e2e`, Node 24) and passes its port in the environment, as the PowerShell version does itself. Screenshots land in `build/ui-e2e-mac`, and `scripts/feature-map.mjs build/ui-e2e-mac` works unchanged.
- The notification permission prompt would stop the test, so the app asks for it only when the user turns notifications on, never on first start.
- CI: a `mac` job on `macos-26` (rustup, `cargo build -p pe-ffi`, `brew install xcodegen`, `xcodebuild build`, ImapKit, `xcodebuild test -only-testing:InboxClassicUITests`), uploading an ad-hoc signed `InboxClassic.app.zip` and the screenshots. Release signing stays on this Mac.

## Phase 2: Linux (7 to 9 weeks)

### Setting up, from this Mac

Two environments, both scripted like the Windows ones:

**Docker (OrbStack, installed), for building and for the headless tests.** `linux/Dockerfile` from `ubuntu:26.04` installs `build-essential pkg-config libgtk-4-dev libadwaita-1-dev libwebkitgtk-6.0-dev` (GTK 4.22.4, libadwaita 1.9.1, WebKitGTK 2.52.6 in 26.04.1), rustup (Ubuntu's own rustc is 1.93, the workspace follows current stable), Node 24 for ImapKit, and for the e2e `xvfb dbus-daemon at-spi2-core python3-dogtail imagemagick`.

- `scripts/linux-build.sh [amd64|arm64]`: builds the image and runs `cargo build --release --locked` in `linux/` with the Cargo target under `build/cargo-linux-<arch>`. arm64 runs natively; `--platform linux/amd64` runs through Rosetta in OrbStack, slower but fine for a release build.
- `scripts/linux-test.sh`: `cargo test` and clippy in the container.
- `scripts/linux-ui-e2e.sh`: `xvfb-run` plus `dbus-run-session`, the dogtail driver, screenshots to `build/ui-e2e-linux`. The same image is CI's container, so local and CI are identical.

**QEMU (installed), for the real desktop.** GNOME on Wayland, the tray, notifications, the dock badge, the portal file dialogs, the `.deb` install and the mailto registration are only real on a desktop. `scripts/linux-vm.sh create|start|stop|ssh|run|screenshot`:

- `create` downloads `ubuntu-26.04-desktop-arm64.iso`, makes a 40 GB qcow2 under `build/vm/` and boots the installer: `qemu-system-aarch64 -M virt -accel hvf -cpu host -smp 6 -m 8G`, UEFI from `$(brew --prefix)/share/qemu/edk2-aarch64-code.fd`, `virtio-gpu-gl-pci` with `-display cocoa,gl=on`, `qemu-xhci` with a keyboard and tablet, `virtio-net` with `hostfwd=tcp::2222-:22`, and a QMP socket. The install is interactive once (15 minutes), then `apt install openssh-server`, automatic login, and a disk snapshot to return to.
- `run` does what `win-run.sh` does: rsync the tree over ssh, install the `.deb`, start the app on the desktop (`WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 systemd-run --user --scope inbox-classic`).
- `screenshot` asks QEMU over QMP for `screendump`: a picture of the VM's display from outside, so no tool inside the guest and no GNOME screenshot restrictions on Wayland.
- UTM (`brew install --cask utm`) is the same QEMU with a window and is fine for poking around by hand; the scripts assume plain QEMU so they can run unattended.

### Layout

```
linux/
  Cargo.toml                  package inbox-classic, its own [workspace] (so core's `cargo test --workspace` on the
                              Mac and Windows never builds GTK), path dependencies on ../core/crates/pe-core and
                              pe-html, its own Cargo.lock; [package.metadata.deb] for cargo-deb
  Dockerfile
  build.rs                    commands.rs from ../core/commands.toml (checked against the committed copy)
  src/
    main.rs                   adw::Application: actions and accelerators from the command table, G_APPLICATION_HANDLES_OPEN
                              for mailto: and .eml, single instance through GApplication
    core.rs                   pe_core::Core and its Events delivered to the GTK main loop (glib::spawn_future_local)
    main_window.rs            adw::ApplicationWindow, two gtk::Paned, the header bar with the toolbar and the search entry
    folders.rs                gtk::ListView over a gtk::TreeListModel, drop target for messages
    messages.rs               gtk::ColumnView over a gio::ListModel implementation that pages through the core
    preview.rs, editor.rs     webkit6::WebView, locked down (below)
    compose.rs, complete.rs   entries with a completion gtk::Popover (EntryCompletion is deprecated), the format bar
    accounts.rs, sign_in_apps.rs, outbox.rs, help.rs, print.rs
    tray.rs                   StatusNotifierItem with ksni; notify.rs: gio::Notification, the LauncherEntry badge
    generated/commands.rs
  data/
    com.inboxclassic.InboxClassic.desktop, .metainfo.xml, icons/hicolor/..., inbox-classic.gresource.xml (help, brands)
  flatpak/com.inboxclassic.InboxClassic.json
  e2e/ui-e2e.py               the dogtail driver of the shared scenario
```

Crates (current versions on crates.io): `gtk4` 0.11, `libadwaita` 0.9, `webkit6` 0.6, `ksni` 0.3, `zbus` 6 (the badge signal), `cargo-deb` 3.8 as a tool.

### The web views

The same lockdown as WebView2's, by WebKitGTK's means:

- `WebKitSettings`: `enable-javascript` off for the preview and the help (the editor page's own script runs with the nonce CSP), `enable-developer-extras` off, local storage, databases, WebGL and the page cache off, `javascript-can-open-windows-automatically` off.
- An ephemeral `WebKitNetworkSession` (nothing on disk), the `inboxclassic` and `cid` schemes through `register_uri_scheme`, the content rules from Phase 0 compiled with `WebKitUserContentFilterStore` (the same JSON as the Mac), `decide-policy` cancelling every navigation but the document's own and opening links with `gtk::UriLauncher`, the `create` signal refusing new windows.
- The web process sandbox (bubblewrap) is on by default in the 6.0 API.
- The editor: `WebKitUserContentManager::register_script_message_handler("host")` receives the page's strings; `evaluate_javascript` runs the six functions. Print: `webkit6::PrintOperation::run_dialog`.

### The windows, in order

| Windows (`app/src`)                         | Linux                                                                                                                                                                                                          | Notes                                                                             |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `main.cpp` frame, splitters, menus          | `adw::ApplicationWindow`, `gtk::Paned` twice, a header bar with the toolbar and a primary menu; `gio::SimpleAction`s and accelerators from the command table                                                   | GNOME has no menu bar; the menu is the header bar's. Ctrl shortcuts as on Windows |
| `mailbox.cpp` folder tree                   | `gtk::ListView` on a `gtk::TreeListModel`                                                                                                                                                                      | Drop target with a message-ids GType                                              |
| `mailbox.cpp` message list                  | `gtk::ColumnView`, sortable, its `gio::ListModel` paging through the core                                                                                                                                      | GTK 4 list views are virtual by design                                            |
| `mailbox.cpp` reading pane                  | A header box and `preview.rs`                                                                                                                                                                                  | `gtk::FileDialog` (the portal dialog on GNOME), Downloads by default              |
| `accounts.cpp`                              | An `adw::Window` with the two steps                                                                                                                                                                            | Sign-in opens the browser with `gtk::UriLauncher`                                 |
| `compose.cpp`, `complete.cpp`, `editor.cpp` | A window; `gtk::Entry`s with a completion popover; `gtk::DropTarget` for files on the window                                                                                                                   | The editor web view never sees file drops                                         |
| `outbox.cpp`, `signinapps.cpp`              | Windows with a `gtk::ColumnView`                                                                                                                                                                               |                                                                                   |
| `help.cpp`                                  | A scripts-off web view with `pe_help_page("linux")`                                                                                                                                                            | F1                                                                                |
| `print.cpp`                                 | `WebKitPrintOperation`                                                                                                                                                                                         |                                                                                   |
| `tray.cpp`                                  | `ksni` StatusNotifierItem (shown by Ubuntu's AppIndicator extension), `gio::Notification` for new mail, the unread count through the `com.canonical.Unity.LauncherEntry` D-Bus signal that Ubuntu's dock shows | Without a tray host the app quits with its last window                            |
| `ui.cpp` preferences                        | `glib::KeyFile` in `$XDG_CONFIG_HOME/inbox-classic/settings.ini` (no GSettings schema to install)                                                                                                              |                                                                                   |
| `main.cpp` default app, mailto, .eml        | `MimeType=x-scheme-handler/mailto;message/rfc822;` in the `.desktop` file, `xdg-settings set default-url-scheme-handler mailto ...` from the menu item                                                         | The store is `$XDG_DATA_HOME/inbox-classic`                                       |
| `main.cpp` command line                     | The same four flags                                                                                                                                                                                            |                                                                                   |

### Packaging

- `cargo deb` from `linux/Cargo.toml`: dependencies from `dpkg-shlibdeps` (`libgtk-4-1`, `libadwaita-1-0`, `libwebkitgtk-6.0-4`), assets (the binary, the `.desktop` file, the icons, the metainfo for the App Center, `THIRD-PARTY-NOTICES.txt` from `scripts/notices.mjs` extended to the Linux crate, `LICENSE`). `scripts/linux-package.sh` builds `InboxClassic-amd64.deb` and `InboxClassic-arm64.deb` in Docker on this Mac, and `scripts/release.sh` calls it and lists both in `hashes.txt`.
- The version: the Linux crate is outside the core workspace, so `linux/Cargo.toml` carries its own `version`, kept equal by release-please (`extra-files` in `release-please-config.json` with an `x-release-please-version` marker), and `release.yaml` runs `cargo update --workspace` in `linux/` as it does in `core/` so `linux/Cargo.lock` follows on the release PR.
- Flatpak after the `.deb` works: the manifest on `org.gnome.Platform` 50 with the `rust-stable` SDK extension, cargo sources through `flatpak-cargo-generator`, permissions `--share=network --socket=wayland --socket=fallback-x11 --talk-name=org.freedesktop.secrets --talk-name=org.kde.StatusNotifierWatcher --filesystem=xdg-download`; then Flathub.
- Updates: an apt repository signed with the release GPG key on `inboxclassic.com/apt` is the later step; until then the `.deb` from the release page, and Flatpak updates itself.

### The UI end-to-end test and CI

- `linux/e2e/ui-e2e.py` with dogtail (GNOME's own tool, packaged as `python3-dogtail`, AT-SPI under the hood; GTK 4 exposes every widget) under `xvfb-run` and `dbus-run-session`, `GSK_RENDERER=cairo` so no GL is needed, widgets found by the accessible labels from the `[controls]` table, screenshots with ImageMagick's `import -window root` under the same names, ImapKit from `core/e2e`, checks over its REST API. Wayland itself is exercised in the VM, not in the container.
- CI: a `linux` job on `ubuntu-latest` with `container: ubuntu:26.04` (the Dockerfile's base, so identical to the local run): apt, rustup, `cargo clippy -- -D warnings`, `cargo build --release --locked`, `cargo deb`, the e2e, uploading the `.deb` and the screenshots. A second run on `ubuntu:26.10` catches library changes early.

## Releasing on three platforms

Every release is built from the release Mac and nothing is published until every platform's package exists, as today. `scripts/release.sh` keeps its shape (the checks first, then the builds, then `hashes.txt`, then the upload and the publish) and gains the two platforms. The Mac part lands with the first Mac release, the Linux part with the first Linux release.

**What stays.** release-please opens the release PR on master; merging it drafts the release and pushes the tag; `release.yaml` updates `core/Cargo.lock` on the PR, and from Phase 2 also `linux/Cargo.lock`. The Mac reads the version from `core/Cargo.toml` at build time (`mac-build.sh` passes it to `xcodebuild` as `MARKETING_VERSION`, the way CMake reads it for Windows), so only `linux/Cargo.toml` carries a second copy, written by release-please. The release notes are release-please's changelog, for all platforms at once, with human notes written into the release PR as `cut-release` does.

**Checks before any build,** all failing fast as now: a clean tree at the tag, CI green for the commit including the `mac` and `linux` jobs, the Windows machine reachable, Docker running, Xcode selected, `SIGN_WIN_ACCOUNT` and `SIGN_WIN_PROFILE`, the Developer ID certificate and the notary credentials in the keychain, the Sparkle signing key, and the GPG passphrase asked up front.

**The builds,** Windows first (the slowest, on another machine), then the Mac (notarization takes minutes), then Linux, each into `dist/`:

| File                                               | Built                                                                                                     | Signed                                                                                           | Checked before upload                                                                                                                                                                    |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `InboxClassic-Setup.exe`                           | on the Windows build machine by `scripts/build-installer.sh`, unchanged                                   | Azure Artifact Signing: the exe, the uninstaller and the installer                               | the signature, as `sign-win.sh` checks it; the staged exe run with `--version` on the build machine                                                                                      |
| `InboxClassic.dmg`                                 | here by `scripts/mac-package.sh`: `mac-build.sh`, then the bundle, then the DMG                           | Developer ID Application, hardened runtime, notarized and stapled, the app and the DMG both      | `codesign --verify --deep --strict`, `spctl --assess --type open --context context:primary-signature`, `stapler validate`; the app copied out of the DMG and run with `--version`        |
| `InboxClassic-amd64.deb`, `InboxClassic-arm64.deb` | here in Docker by `scripts/linux-package.sh`, arm64 natively and amd64 through Rosetta                    | not as files; `hashes.txt` covers them, and the apt repository signed with the release key later | `dpkg-deb --info` and `lintian`; installed and run with `--version` in a clean `ubuntu:26.04` container of each architecture; the arm64 one also on the QEMU desktop (`linux-vm.sh run`) |
| `THIRD-PARTY-NOTICES.txt` in each package          | `scripts/notices.mjs`, extended from the Windows crate list to the Mac (plus Sparkle) and the Linux crate |                                                                                                  | present in each package                                                                                                                                                                  |
| `hashes.txt`                                       | here, SHA-256 of the four packages                                                                        | GPG, the Postalsys Releases key, as now                                                          | `gpg --verify` with `VALIDSIG` of that key                                                                                                                                               |

**Then:** `gh release upload` of the four packages and `hashes.txt` with `--clobber`, the draft published as latest, `generate_appcast` over the DMG with the release notes as its description, `appcast.xml` committed and pushed to `../inboxclassic.com` (GitHub Pages deploys it, Sparkle clients see the update at their next check), and once the Flatpak exists, the Flathub manifest's tag and hash bumped (a pull request there, automated later with flatpak-external-data-checker). The homepage's version line, if it shows one, is part of the same push.

`BUILD_ONLY=yes` stays, and `PLATFORMS=windows,mac,linux` (the default) selects what to build, so one platform's package can be rebuilt after a failure without rebuilding the others; the upload step takes what is in `dist/`.

## The homepage

`../inboxclassic.com`: one static `index.html` with no scripts today, five screenshots in `img/` from `build/ui-e2e`, prettier-formatted, served by GitHub Pages with DNS at Cloudflare. Decided: it detects the visitor's platform and shows all three.

- **Copy.** "A fast, simple mail program for Windows" and the meta description become Windows, Mac and Linux. The Features and Questions sections lose their Windows-only wording: the Credential Manager becomes "your system's password store: the Credential Manager, the Keychain, GNOME Keyring", the tray and taskbar paragraph names the Dock badge and the GNOME equivalents, "Windows 10 and 11" becomes a line per platform.
- **Downloads.** The hero and the closing CTA list all three, each with its requirements: Windows 10 and 11 (`InboxClassic-Setup.exe`); macOS 26 or newer on Apple silicon (`InboxClassic.dmg`); Ubuntu 26.04 or newer (`InboxClassic-amd64.deb`, with the arm64 build and later Flathub linked beside it). The first script on the page reads `navigator.userAgentData.platform`, falling back to `navigator.platform` (Safari has no `userAgentData`), and makes the visitor's platform the main button with the other two as text links under it. Without JavaScript the three buttons show as written, Windows first, so nothing depends on the script.
- **Screenshots.** `img/windows/`, `img/mac/` and `img/linux/` with the same five names, each from that platform's own end-to-end run, cropped to the window the same way. The script swaps the `img` sources to the visitor's platform; Windows is the HTML default, and a `<picture>` element cannot do this because the choice is the OS, not the viewport. `scripts/homepage-screenshots.sh` in the app repo copies and crops (ImageMagick, installed) the current `build/ui-e2e`, `build/ui-e2e-mac` and `build/ui-e2e-linux` screenshots into the homepage checkout, so refreshing them when a window changes stays one command, as CLAUDE.md asks.
- **Files the release adds.** `appcast.xml` for Sparkle at the root from the first Mac release; `apt/` for the signed apt repository later.
- **Timing.** The Mac download, copy and screenshots go live with the first Mac release; Linux with the first Linux release; in between the page says Windows and Mac. The homepage's README and the app's CLAUDE.md get the folder layout and the refresh script.

## Phase 3: three shells in step

The cost of three shells is that every feature is UI work three times. These rules and checks make a missing third of a feature visible, and some of them (1, 2, 6) make it a build failure.

1. **The core computes, the shells show.** Already the rule for mail data; now also for every string, count and decision a user sees. A shell reads values and calls operations; it never derives.
2. **One command table, three generated enums** (`core/commands.toml`, Phase 0). Handled exhaustively, so a new command fails the build of the shell that ignores it. Menus, shortcuts and toolbar icons come from the table, so they cannot drift.
3. **One scenario, three drivers, one gate.** The e2e steps are written once in `scripts/ui-e2e/SCENARIO.md` (numbered steps, the screenshot name of each, the REST check of each). `ui-e2e.ps1`, `mac/UITests` and `linux/e2e/ui-e2e.py` implement them. `scripts/feature-map.mjs --check <dir>` fails when a screenshot that the feature list names is missing, and CI runs it for each platform's screenshots. A feature with no screenshot on one platform fails CI there.
4. **One help, one icon set, one version, one changelog.** `help.html` with `data-os` (Phase 0), the SVGs in `app/res/icons` (`build-icons.sh` also writes the Mac template images and the Linux symbolic icons), the version in `core/Cargo.toml`, release-please's changelog.
5. **One release, one homepage.** `scripts/release.sh` builds every platform's package, boot-tests each with `--version`, writes one `hashes.txt`, uploads all, publishes the draft, then the appcast (section Releasing on three platforms). The homepage shows a download and the screenshots of each platform, refreshed by `homepage-screenshots.sh` from the three end-to-end runs (section The homepage).
6. **A PR touches all three or says why.** `scripts/check-shells.sh` in CI: when `core/include/inbox_classic.h`, `core/commands.toml` or `scripts/feature-map.mjs` changed, `app/`, `mac/` and `linux/` must all have changed, unless the PR carries the label `shells: partial` and its description names what is left for which platform and the issue tracking it. A PR template lists the checklist.
7. **A parity table by feature.** `docs/shells.md`: a row for each feature of `feature-map.mjs`, the file and function on each platform. Kept by hand, checked by rule 3.
8. **CLAUDE.md** gets a "Three shells" section: what each shell is and where each window lives on each platform, the commands to build, run, screenshot and e2e-test each, the style references for each (`../imapkit-win` for Windows, Apple's HIG for AppKit, GNOME's HIG for GTK), and the rule that a feature lands on all three platforms in the same PR, with the order of work: core and its tests, then `commands.toml` or the header, then the three shells, then the scenario step and the feature-map entry, then the help.

## Schedule

One developer, full time. The Mac first: the larger market for a desktop mail client, and it is built on this machine.

| When                     | What                                                                                                                                                                                   |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-11-09 to 2026-11-20 | Phase 0: password backends, content rules, `editor.js`, help, command table, presentation code                                                                                         |
| 2026-11-23 to 2026-12-04 | Xcode 27 and the Mac project; the web view spike and the hostile message; go or no-go                                                                                                  |
| 2026-12-07 to 2027-01-29 | The Mac windows in order; a first internal build with accounts and reading by mid-January                                                                                              |
| 2027-02-01 to 2027-02-26 | Packaging, notarization, Sparkle, XCUITest, the `mac` CI job; `release.sh` builds Windows and the Mac; the homepage gets the Mac download, copy and screenshots; the first Mac release |
| 2027-03-01 to 2027-04-16 | The Linux shell in Docker, checked on the QEMU desktop; `.deb` and `linux-package.sh`                                                                                                  |
| 2027-04-19 to 2027-05-07 | dogtail e2e, the `linux` CI job, Flatpak; `release.sh` builds Linux too; the homepage gets Linux; the first Linux release                                                              |
| 2027-05-10 to 2027-05-21 | Phase 3 gates, CLAUDE.md, the parity table; the first release on all three                                                                                                             |

About 6 months with one developer, as decided. Should a second one join, Linux can start right after Phase 0, since the content rules and the command table serve both, which brings it to about 4 months.

## Risks

- **A WebKit load that cannot be refused.** Mitigated by the spike before anything else and the hostile message checked by the e2e on every platform; the fallback is stripping the construct in `pe-html` for the WebKit document.
- **Keychain prompts on dev builds** when the signing identity changes: sign Debug builds with the Developer ID too, or `--memory-passwords`.
- **No tray on vanilla GNOME.** Ubuntu's AppIndicator extension is on by default; the app works without a tray and quits with its last window where it is missing.
- **AT-SPI and Xvfb flakiness** in headless e2e: generous waits as in `ui-e2e.ps1`, retries on the known flaky steps, and the VM for anything the container cannot show.
- **Three times the UI work for every feature.** The whole of Phase 3; it only works if the rules are enforced by CI, not by memory.
- **Node for ImapKit on Linux**: Ubuntu's `nodejs` may not be 24; the Dockerfile takes it from the official tarball.
- **Apple silicon only on the Mac** leaves Intel Macs on macOS 26 out. Accepted by decision 2; a universal binary (a second Rust target and `lipo`) is a day's work if that changes.
- **A release that fails halfway** (notarization down, the Windows machine asleep) after other packages were built: `PLATFORMS=` rebuilds one platform and the upload takes what is in `dist/`, so a release never has to start over.
- **The homepage script picks the wrong platform** (an unusual user agent): the other two downloads are always one line below, and without JavaScript all three show.
