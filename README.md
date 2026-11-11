# Inbox Classic

An email client for Windows, the Mac and Linux in the style of Outlook Express: folders on the left, messages on top, the reading pane below. The protocol and parsing code is Rust, ported from our own JavaScript libraries, the same on every platform; each platform's windows are a thin native layer on top of it: C++ and Win32 in the classic look on Windows, Swift and AppKit on the Mac, Rust and GTK 4 on Linux. Homepage: https://inboxclassic.com

- Any IMAP and SMTP account, its servers looked up from the address; Gmail, Google Workspace, Outlook.com and Microsoft 365 add with Sign in with Google or Microsoft, so the password is typed on their page, never into the app
- Sign-in apps: an OAuth client of your own at Google, Microsoft or any OpenID Connect provider, for signing in through the browser with it; each sign-in app, the built-in ones included, can be turned off for new accounts
- Mail kept on the computer for reading offline, several accounts in one folder tree, folders, flags, .eml import and export, printing
- Search every folder as you type, by subject, people, file names and text, from a local full-text index, with Gmail's search syntax (`from:`, `is:unread`, `has:attachment`, `in:sent`, `before:` ...)
- HTML mail sanitized and shown without scripts, remote pictures blocked until allowed, quoted history and forwarded mail folded away
- An HTML editor that sends plain text when nothing is formatted, drafts saved on the server, an Outbox for what can not go yet; a signature for each account, and addresses completed from the people you write to and hear from
- New mail as it arrives (IMAP IDLE), with a notification and an unread count on the taskbar, the Dock or the dock of GNOME, and a tray icon on Windows and Linux; the default mail app for `mailto:` links
- Drag messages onto folders, Mark All Read, Junk and Not Junk (`$Junk`/`$NotJunk`), one-click Unsubscribe (RFC 8058), calendar invitations shown readably, brand logos (BIMI)
- No telemetry and no account with us: the app talks to your mail servers, and beyond them only when a message asks for it: a mailing list's unsubscribe address once you agree, a brand's logo address when your mail server approved the logo

## Installing

Each release has a `hashes.txt`, signed with the Postalsys Releases GPG key, to check the downloads against.

**Windows**: run `InboxClassic-Setup.exe` from the [latest release](https://github.com/postalsys/inbox-classic/releases/latest/download/InboxClassic-Setup.exe). It needs 64-bit Windows 10 or 11 with the Microsoft Edge WebView2 Runtime, which Windows 11 includes. It installs for the current user, no administrator rights needed, to `%LOCALAPPDATA%\Programs\Inbox Classic`, with a Start menu shortcut and an entry in Installed apps. The setup, the app and the uninstaller are signed by Postal Systems OÜ.

Running the setup of a newer version updates the installed one in place; the accounts and the mail downloaded, in `%LOCALAPPDATA%\InboxClassic`, are kept. Uninstalling asks whether to remove those too; the mail on the servers always stays. The user help is built in: F1 in the app (`core/crates/pe-html/src/help.html`, one page for every platform).

**Mac**: open `InboxClassic.dmg` from the [latest release](https://github.com/postalsys/inbox-classic/releases/latest/download/InboxClassic.dmg) and drag Inbox Classic to Applications. It needs macOS 26 or newer on Apple silicon. The app is signed by Postal Systems OÜ and notarized by Apple, and it updates itself (Inbox Classic > Check for Updates). Mail and settings are in `~/Library/Application Support/Inbox Classic`, passwords in the login keychain.

**Linux**: install the `.deb` of the [latest release](https://github.com/postalsys/inbox-classic/releases/latest) for your machine, `InboxClassic-amd64.deb` or `InboxClassic-arm64.deb`, with `sudo apt install ./InboxClassic-amd64.deb`. It needs Ubuntu 26.04 or newer (GTK 4, libadwaita and WebKitGTK come from Ubuntu). A newer `.deb` installs over the old one. Mail is in `~/.local/share/inbox-classic`, passwords in the keyring (GNOME Keyring).

**Arch Linux and Omarchy**: download `InboxClassic-x86_64.pkg.tar.zst` (or `InboxClassic-aarch64.pkg.tar.zst` on ARM) from the [latest release](https://github.com/postalsys/inbox-classic/releases/latest) and install it with `sudo pacman -U InboxClassic-x86_64.pkg.tar.zst`; pacman adds GTK 4, libadwaita and WebKitGTK from Arch's repositories (on a new Omarchy, run its Update first, so pacman has its package lists). Install a newer one the same way. Or build it from [`linux/arch/PKGBUILD`](linux/arch/PKGBUILD) with `makepkg -si`, which compiles the release's source.

## How it is put together

Everything that a remote party writes, such as IMAP responses, message headers and bodies, attachment names and autoconfig documents, is parsed in Rust. The C++ app only draws what the core has already decoded and validated:

- **Rust core**: IMAP (a port of [ImapFlow](https://github.com/postalsys/imapflow)), SMTP and MIME building (a port of the client parts of [Nodemailer](https://github.com/nodemailer/nodemailer)), MIME parsing (a port of [postal-mime](https://github.com/postalsys/postal-mime)), separating what a sender wrote from quoted history (a port of [email-content](https://github.com/postalsys/email-content)), HTML sanitizing (ammonia), the local store (SQLite), account autodiscovery over DNS-over-HTTPS, the OAuth 2.0 sign-in (PKCE, loopback redirect) and the passwords and tokens kept in the system's own store (the Windows Credential Manager, the Mac's keychain, the Secret Service on Linux). It is linked into the Windows and Mac apps as a static library behind a small C API (`pe-ffi`, the only crate with `unsafe` code); the Linux app, being Rust, links it as a crate.
- **WebView2**: renders the sanitized message HTML with scripts off, network requests refused (remote images only after the user allows them) and links opened in the default browser. The compose editor and the Print window are the only pages that run a script, their own, allowed by a nonce in their Content-Security-Policy.
- **On the Mac and Linux**, WKWebView and WebKitGTK show the same documents the same way: served from the app's own scheme, every other load blocked by the core's content rules.
- **The windows**: C++ on Windows, in the classic Outlook Express look; Swift and AppKit on the Mac; Rust, GTK 4 and libadwaita on Linux. None parses anything a remote party wrote. `docs/shells.md` says where each feature lives on each platform.

## Layout

| Path                           | What                                                                                                                  |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `core/`                        | Cargo workspace with the Rust core, built as one static library (`pe_ffi.lib`)                                        |
| `core/include/inbox_classic.h` | the C API of the core, generated by cbindgen from `core/crates/pe-ffi`                                                |
| `core/e2e/`                    | the ImapKit test server the end-to-end tests run against                                                              |
| `app/`                         | the Win32 GUI (C++, common controls without visual styles for the classic look, WebView2 for message bodies)          |
| `app/res/`                     | the manifest and the icons (Fluent UI System Icons, SVG and the bitmap strips made from them)                         |
| `mac/`                         | the Mac app (Swift package: AppKit, WKWebView, Sparkle), with its in-process UI end-to-end test                       |
| `linux/`                       | the Linux app (Rust: GTK 4, libadwaita, WebKitGTK), its Dockerfile and its packaging                                  |
| `core/commands.toml`           | the commands of the menus of all three apps, generated into each                                                      |
| `docs/`                        | the plan of the Mac and Linux apps, and where each feature lives on each platform                                     |
| `scripts/`                     | build, test, package, release and screenshot helpers: `win-*` on the build machine, `mac-*` here, `linux-*` in Docker |
| `installer/`                   | the NSIS installer script                                                                                             |

## Building

The Rust core builds and tests on any platform with Rust 1.90 or newer:

```
cd core
cargo test --workspace
```

The end-to-end tests run against [ImapKit](https://github.com/postalsys/imapkit), an IMAP and SMTP test server with an OAuth 2.0 / OpenID Connect provider for the sign-in tests, and are skipped until it is installed: `npm ci` in `core/e2e` (Node.js 24). `PE_NETWORK_TESTS=1` also runs the tests that need the internet (account autodiscovery, and that Google and Microsoft accept the built-in OAuth clients).

The app builds on Windows with Visual Studio 2022 Build Tools (C++ workload, which brings CMake and Ninja) and Rust (`rustup`, the MSVC toolchain):

```
scripts\win-build.cmd      :: gives build\InboxClassic.exe
```

From a Mac, `scripts/win-build.sh` copies the working tree to the Windows build machine (`WIN_HOST`, `WIN_DIR`, see `scripts/win-env.sh`) and builds it there, `scripts/win-test.sh` runs the Rust tests there, `scripts/win-run.sh` starts the app on its desktop, `scripts/win-screenshot.sh out.png` takes a screenshot of the window and `scripts/win-ui-e2e.sh` runs the UI end-to-end test (`scripts/ui-e2e.ps1`) on its desktop.

## Installer

`scripts/build-installer.sh` builds `dist/InboxClassic-Setup.exe` from a Mac: the app is built and staged on the Windows build machine, then NSIS (`brew install makensis`) packs it. The installer works per user without administrator rights and upgrades in place. With `SIGN_WIN_ACCOUNT` and `SIGN_WIN_PROFILE` set, the exe, the uninstaller and the installer are signed with Azure Artifact Signing (`scripts/sign-win.sh`, needs `jsign`).

Signing in to Gmail, Outlook.com and Microsoft 365 through the browser (OAuth 2.0, authorization code with PKCE and a loopback redirect) works in every build: the Google Desktop App client and the Microsoft public client are built in, and `PE_GOOGLE_CLIENT_ID` / `PE_GOOGLE_CLIENT_SECRET` / `PE_MICROSOFT_CLIENT_ID` at build time replace them. The Google client is in Google's testing state (only its test users can sign in), so it is turned off out of the box; users can add a client of their own as a sign-in app (File > Accounts > Sign-in Apps), found through OpenID Connect discovery.

## Releasing

Releases follow ImapKit Desktop's flow. Commits use Conventional Commit messages (`feat:`, `fix:` ...), and release-please keeps a release PR up to date on master (`release-please-config.json`, `.github/workflows/release.yaml`). Merging the PR bumps the version in `core/Cargo.toml` (the workflow brings `Cargo.lock` along), writes the changelog, pushes the `v<version>` tag and drafts the release.

Then, on the release Mac, check out the tag and run `scripts/release.sh`. It checks that CI passed for the tag, builds the installer on the Windows build machine, signs the exe, the uninstaller and the setup with Azure Artifact Signing, writes `hashes.txt` signed with the release GPG key, uploads both to the draft and publishes it. The setup has no version in its name, so https://github.com/postalsys/inbox-classic/releases/latest/download/InboxClassic-Setup.exe always gets the latest release, which is the download link of inboxclassic.com. `BUILD_ONLY=yes` builds and signs without uploading.

## License

Inbox Classic is licensed under the [MIT license](LICENSE). The third-party code it includes, and their licenses, are listed in `THIRD-PARTY-NOTICES.txt` of the installer (`scripts/notices.mjs`).
