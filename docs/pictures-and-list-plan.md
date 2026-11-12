# Trusted senders' pictures, unread only, badges, .eml files and future dates

Five changes, each in all three apps. Overview: `docs/pictures-and-list-overview.html`.

## Decisions

- **Trusted senders:** a sender's address or their whole domain, in one list in Options with Remove.
- **Only when verified:** a trusted sender's pictures load only when the provider's Authentication-Results say the
  message really comes from that domain (DKIM or DMARC pass, as the sign-in codes and brand logos check). A forged
  message asks as before, and says it could not be confirmed. Never in Junk E-mail.
- **Contacts are not trusted** by being in the Address Book (it fills itself from everyone you write to and hear from).
- **Always download pictures:** a checkbox in Options, off by default, with a line on what it tells senders. Never in
  Junk E-mail.
- **Unread only:** one setting for every folder, remembered. A message read while the filter is on stays in the list
  until you leave the folder.
- **.eml files:** registered on all three (Open With), and Options gets "Open .eml files with Inbox Classic", which sets
  it as the default where the system allows (Mac and Linux directly; Windows opens its Default Apps page).
- **Future dates:** the list sorts and shows a message's own date, but never later than when the server received it.
- **Windows taskbar badge:** the unread count as an overlay on the taskbar button (99+ past 99). The Mac's Dock and
  Ubuntu's dock already show it.

## 1. Pictures from trusted senders, or always

### Core

- `pe-store`: a migration with `trusted_senders(id, kind, value, added)`, `kind` `address` or `domain`, values in lower
  case and unique; `trust_sender`, `untrust_sender`, `trusted_senders`. The setting `always_load_pictures` in the
  store's settings.
- `pe-core`: one decision where the view is built (`view.rs`): pictures load when the user allowed this message, or
  `always_load_pictures`, or the sender's address or domain is in the list **and** `authres` confirms the From domain
  (a new `authres::from_verified(headers, trusted, domain)`: `dmarc=pass header.from=<domain>`, or `dkim=pass` with a
  `header.d` aligned to it); never for a message in the account's Junk folder.
- `MessageView` gains what the bar needs: the sender's address and domain, whether they can be trusted (verified), and
  the bar's words from the catalog ("Some pictures have been blocked…", "Always from ann@shop.com", "Always from
  everyone at shop.com", "Inbox Classic cannot confirm this message is from shop.com").
- C API: `pe_trust_sender(core, value, kind)`, `pe_untrust_sender`, `pe_trusted_senders` (a list), the setting through
  the existing settings calls. Tests: the list, address and domain matching (subdomains not included), verified only,
  Junk never, always; e2e_core with a message carrying Authentication-Results.

### The apps

- **The pictures bar** keeps Download Pictures (this message) and adds the two Always choices: on Windows a drop-down
  arrow at the bar's right (a menu, as Outlook's bar has); on the Mac and Linux a menu button beside Download Pictures.
  An unverified sender's bar has Download Pictures only, and its line says why.
- **Options:** under Read (Windows' Read tab, the Mac's and Linux's Reading section) "Download pictures in all
  messages" with its warning, and "Trusted senders…", a list with Remove (Windows a dialog with a list view; the Mac a
  sheet with a table and −; Linux an `AdwPreferencesPage` group with a remove button a row).

## 2. Unread only

- **Core:** the list's scope gets `unread_only` (folders, All Inboxes, search, conversations: a conversation shows
  while one of its messages is unread), and a set of messages kept for the moment: those read since the filter was
  turned on, until the folder changes. Counts and the status bar ("Unread only: 3 messages") from the core; an empty
  list says "No unread messages".
- **Command** `hide_read` in `commands.toml`, a toggle in View ("Hide Read Messages", as Outlook Express named it).
- **Windows:** View > Hide Read Messages and a toolbar button (a Fluent filter icon through `build-icons.sh`).
- **Mac:** the filter button in the toolbar (the SF Symbol `line.3.horizontal.decrease.circle`, filled when on), as
  Mail has it, and View > Hide Read Messages.
- **Linux:** a toggle button in the header bar (`funnel-symbolic`) and the item in the primary menu.
- Remembered in each app's preferences.

## 3. The Windows taskbar badge

- `app/src/tray.cpp`: `ITaskbarList3::SetOverlayIcon` with a small icon drawn for the count (a red circle with white
  digits, "99+" past 99, rebuilt when the count changes), cleared at none; the count is the one the tray already gets
  from the core. Windows' own setting to hide badges applies.
- The Mac (`NSApp.dockTile.badgeLabel`) and Linux (`com.canonical.Unity.LauncherEntry`) stay as they are; the help says
  where each shows it.

## 4. Opening .eml files

- **Core:** a message read from a file into a view without a store row (`pe_file_message`), for the message window:
  Reply, Reply All, Forward, Print and Save As work; moving, flags and deleting are off (it is no mailbox's).
- **Windows:** the installer registers `InboxClassic.eml` (per user, HKCU), `.eml` `OpenWithProgids` and the app's
  `Capabilities\FileAssociations`, so Default Apps lists it; a start with a .eml path hands it to the running app (as
  a `mailto:` link is) and opens its message window. Options' button opens Default Apps at Inbox Classic.
- **Mac:** `CFBundleDocumentTypes` for `com.apple.mail.email` (rank Alternate); `application(_:open:)` opens message
  windows; the Options button calls `NSWorkspace.setDefaultApplication(at:toOpenContentType:)`.
- **Linux:** the desktop file already names `message/rfc822`; a path argument opens the message window; the Options
  button runs `xdg-mime default com.inboxclassic.InboxClassic.desktop message/rfc822`.

## 5. Future dates

- `pe-store`: the order and the date the list shows become `MIN(COALESCE(date, internal_date), internal_date)`: a
  migration adds it as a virtual generated column `list_date` with its indexes, so the sorts stay on indexes (the
  query plan tests check it); conversations' newest date likewise (`threads.rs`).
- The reading pane's header keeps the message's own Date; when it is later than arrival, Properties says both.
- Tests: a message dated next year sorts and shows at its arrival; one sent a minute before arrival keeps its own time.

## Every change

- Core tests, `e2e_core` / `e2e_ffi` where the C API changes, `cargo fmt`, `clippy -D warnings`.
- `SCENARIO.md` steps, each platform's UI end-to-end test with screenshots (`pictures-2-trusted`, `pictures-3-options`,
  `list-unread-only`, `tray-3-badge`, `files-4-open-eml`), `feature-map.mjs` entries.
- The help topics (pictures-tracking, read-messages, new-mail, save-print-import, default-mail-program) in all five
  languages, the translations marked for review; new strings likewise.
- `/simplify` and `/security-review` on each change, their findings fixed; prettier on Markdown and YAML.
- Commit, push, a pull request a feature, CI watched until green (a flaky job rerun at most three times), then merged.

## Order of work

1. Future dates (store only, small).
2. Unread only.
3. Pictures from trusted senders, or always (the largest).
4. Opening .eml files.
5. The Windows taskbar badge.

## Risks

- Authentication-Results are only as good as the account's provider: with a provider that adds none, no sender is
  verified and the Always choices never apply (the bar says so). `authres::trusted` already decides whose headers count.
- Windows 10 and 11 let no program set itself as a default: the button can only open Default Apps.
- A virtual generated column needs SQLite 3.31 or newer; the bundled one is newer.
