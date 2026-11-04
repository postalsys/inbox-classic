# Where each feature lives on each platform

The three apps are thin windows on the same Rust core (`core/`). A feature that changes what the user sees changes all three, in the same pull request (`scripts/check-shells.sh` checks it); this table says where. The screenshots of the UI end-to-end tests (`scripts/feature-map.mjs`, with `--check <platform>`) show that each one is there.

| Part                                        | Windows (`app/src`, C++ and Win32)           | Mac (`mac/Sources/InboxClassic`, Swift and AppKit)  | Linux (`linux/src`, Rust and GTK 4)          |
| ------------------------------------------- | -------------------------------------------- | --------------------------------------------------- | -------------------------------------------- |
| Startup, command line, menus, commands      | `main.cpp`                                   | `App.swift`                                         | `main.rs`, `app.rs`                          |
| The core's API and events                   | `core.cpp`, `core.h`                         | `Core.swift` (on `core/include/inbox_classic.h`)    | `app.rs` (on `pe-core` directly)             |
| Main window, toolbar, search, status bar    | `main.cpp`, `mailbox.cpp`                    | `MainWindow.swift`                                  | `mailbox.rs`                                 |
| Folder tree                                 | `mailbox.cpp`                                | `Mailbox.swift`                                     | `folders.rs`                                 |
| Message list                                | `mailbox.cpp`                                | `Mailbox.swift`                                     | `messages.rs`                                |
| Reading pane, attachments, bars, logo       | `mailbox.cpp`, `preview.cpp`                 | `Reader.swift`, `WebViews.swift`                    | `reader.rs`, `webview.rs`                    |
| The web views and their lockdown            | `webview.cpp`, `preview.cpp`                 | `WebViews.swift` (content rules of the core)        | `webview.rs` (content rules of the core)     |
| Compose window, format bar                  | `compose.cpp`                                | `Compose.swift`                                     | `compose.rs`                                 |
| HTML editor                                 | `editor.cpp`                                 | `Editor.swift`                                      | `editor.rs`                                  |
| Address completion                          | `complete.cpp`                               | `Compose.swift` (`AddressField`, `AddressEditor`)   | `complete.rs`                                |
| Signature editor                            | `compose.cpp`                                | `Compose.swift` (`SignatureEditor`)                 | `editor.rs`, `accounts.rs`                   |
| Add Mail Account, password, browser sign-in | `accounts.cpp`                               | `Accounts.swift`                                    | `accounts.rs`                                |
| Accounts window                             | `accounts.cpp`                               | `Accounts.swift`                                    | `accounts.rs`                                |
| Sign-in Apps and its editor                 | `signinapps.cpp`                             | `SignInApps.swift`                                  | `sign_in_apps.rs`                            |
| Outbox                                      | `outbox.cpp`                                 | `Outbox.swift`                                      | `outbox.rs`                                  |
| Help                                        | `help.cpp`                                   | `WebViews.swift` (`HelpWindow`)                     | `help.rs`                                    |
| Printing                                    | `print.cpp`                                  | `WebViews.swift` (`Printer`)                        | `webview.rs`                                 |
| New mail: tray, notification, unread count  | `tray.cpp`                                   | `MainWindow.swift` (Dock badge, notifications)      | `tray.rs`, `notify.rs`                       |
| Dialogs, forms, file panels                 | `ui.cpp`                                     | `Dialogs.swift`                                     | `ui.rs`                                      |
| Preferences                                 | `ui.cpp` (registry)                          | `UserDefaults`                                      | `settings.rs` (`settings.ini`)               |
| Icons                                       | `icons.h`, `app/res/toolbar`                 | `Icons.swift` (PDFs made by `scripts/mac-build.sh`) | `linux/data`, made by `linux/build.rs`       |
| UI end-to-end test                          | `scripts/ui-e2e.ps1`                         | `UITest.swift`, `UITestSteps.swift`                 | `e2e.rs`, `e2e/`                             |
| Build, package, boot test                   | `scripts/win-build.sh`, `build-installer.sh` | `scripts/mac-build.sh`, `mac-package.sh`            | `scripts/linux-build.sh`, `linux-package.sh` |

Shared by all three, in the core: the help (`core/crates/pe-html/src/help.html`, with `<!--os:...-->` parts), the commands (`core/commands.toml`, generated into `core/include/commands.h`, `mac/Sources/InboxClassic/Generated/Commands.swift` and `linux/src/generated/commands.rs`), the words for sizes and the account and folder names (`pe-core/src/text.rs`), the documents of the web views and their content rules (`pe-html`), and everything that touches mail data.
