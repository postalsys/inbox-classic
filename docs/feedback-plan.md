# From the feature board: setup export, more languages, All Sent and All Drafts, opening attachments

Four posts of https://features.inboxclassic.com, planned together. Each lands on Windows, the Mac and Linux in the same pull request, as every feature does.

| Post                                            | Feature                                                          | Status on the board |
| ----------------------------------------------- | ---------------------------------------------------------------- | ------------------- |
| [#1](https://features.inboxclassic.com/posts/1) | Export and import settings, accounts and contacts in one file    | planned             |
| [#2](https://features.inboxclassic.com/posts/2) | More languages: all official EU languages, Ukrainian and Russian | planned             |
| [#6](https://features.inboxclassic.com/posts/6) | All Sent and All Drafts across accounts                          | planned             |
| [#9](https://features.inboxclassic.com/posts/9) | Open attachments with a double-click                             | planned             |

Each post moves to `started` when its work begins and to `completed` when it is merged, with a short comment when voters should know something (what was decided, when it ships, a call for translation reviewers).

## Decisions taken

| Question                                   | Answer                                                                                                                                                                                                                                 |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1 Passwords, sign-in tokens, private keys | In the file only when it has a passphrase (then the whole file is encrypted); without one, each account asks for its password once after the import                                                                                    |
| #1 What the file carries                   | Settings, accounts (server settings, account names, signatures, other addresses, order), sign-in apps, contacts with their groups and pictures, OpenPGP keys (own private keys only with a passphrase), message rules, trusted senders |
| #2 When a language is offered              | All 21 at once, not marked as beta; the translations are drafts marked for review in the catalogs, edited later (maybe before the release)                                                                                             |
| #2 The help                                | Every topic in every language                                                                                                                                                                                                          |
| #6 Where All Sent and All Drafts sit       | As All Inboxes: rows after it, each with a row per account under it; Sent Items and Drafts leave the account headings (two or more accounts; one account keeps its own)                                                                |
| #9 Where attachments show                  | A native strip of icons with name and size under the message header, drawn by the app, in the reading pane and a message's own window                                                                                                  |
| #9 Files that can run code                 | Never opened from the message; they can be saved                                                                                                                                                                                       |
| #9 Attachments of encrypted messages       | Open like any other; the first time, a note says the file is stored decrypted on this computer while it is open                                                                                                                        |

## Defaults chosen (say if you want otherwise)

- #1: the file is `Name.inboxclassic` (JSON inside, versioned; encrypted with Argon2id and ChaCha20-Poly1305 when it has a passphrase of 8 characters or more, the rule of key backups). Window positions, open folders, agents' permissions (they are per machine), the store's caches and messages stay out.
- #1: an account already here (same address and servers) is skipped, not replaced; contacts merge as Import Address Book does (an address already in the book is skipped); settings are replaced; rules are added unless the same rule is there, their folders found by path; keys follow the key book's rules (a different key for an address waits for the user).
- #2: Portuguese as written in Portugal; Norwegian is not in the post and stays out. Plural forms come from CLDR through Fluent (Irish has five, Maltese and the Baltic and Slavic languages three or four).
- #6: All Drafts shows how many drafts there are, as a folder of drafts does; All Sent shows no count. A draft opened from All Drafts opens in its own account.
- #9: the strip is keyboard reachable (Tab, arrows, Enter opens, the context menu key); right-click has Open, Save As and Save All; the files open from a private temporary folder cleaned at start and after a day.

## 1. Export and import (#1)

**The core** (`pe-core/src/setup.rs`, `pe-store` readers and writers):

- `export_setup(path, parts, passphrase)` and `read_setup(path, passphrase)` then `import_setup(read, parts)`: the parts are flags (settings, accounts, sign-in apps, contacts, keys, rules, trusted senders). Reading first shows what the file holds (accounts with their servers, how many contacts, keys and rules) so the import window can list it before anything changes.
- Secrets come from and go to the system's password store through `secrets.rs` (accounts' passwords and refresh tokens, sign-in apps' secrets); own private keys are taken out of their wrapping and wrapped again under the new store's master key on import.
- App preferences: the core keeps the list of portable preferences (layout, conversations, notifications, folder list, pictures in the list, language ...) and hands them to the apps as names and values; each app reads and writes its own place (registry, UserDefaults, settings.ini). No JSON crosses the C API.
- Everything read from a file is untrusted input: a size limit, versioned format, every field checked as the account form and the sign-in apps window check them (https issuers, server names, ports), signatures sanitized again, contacts through the vCard rules.

**The apps**: File > Export > Setup... and File > Import > Setup... (on the Mac in the File menu, on Linux in the main menu), and on the first run, Add Mail Account offers "Import a setup from another computer". Export: the parts to include, an optional passphrase typed twice (with the words of what it adds). Import: the passphrase when the file has one, then what the file holds with a check box for each part and each account, then a summary of what was added and skipped.

**Tests**: round trips of every part with and without a passphrase; a wrong passphrase, a changed byte, a newer format version, an empty and an oversized file; partial imports; an account already here; rules whose folders are missing; private keys rewrapped and usable; a fuzz target for the reader. `e2e_core` against ImapKit: export from one store, import into an empty one, both accounts sync and send. UI tests: `setup-1-export`, `setup-2-passphrase`, `setup-3-import-choose`, `setup-4-imported`, `setup-5-first-run`.

## 2. More languages (#2)

Bulgarian, Croatian, Czech, Danish, Dutch, Finnish, Greek, Hungarian, Irish, Italian, Latvian, Lithuanian, Maltese, Polish, Portuguese, Romanian, Slovak, Slovenian, Swedish, Ukrainian and Russian: 21 languages, each about 1,200 messages and 50 help topics.

**First, every list of languages from one place**: `pe_i18n::LANGUAGES` (with each language's name in itself) drives the Windows installer's languages and its strings (from the catalogs), the sign-in button pictures (`scripts/build-sign-in-buttons.sh`, with Roboto's Greek and Cyrillic subsets and a check that the button font covers every language), the Linux `.desktop` and metainfo translations (generated), the Mac Help Book's search stop words, the homepage's help languages, and the UI tests' language tours.

**Then the languages**, in three pull requests of seven: catalogs and help drafted from English (with GLOSSARY.md's terms added per language: key, fingerprint, signed, encrypted, folder names as each platform's mail program in that language says them), every new message marked `# review: new`, the help passages in `<!--review-->`, so `scripts/i18n-review.mjs` lists them for a native review later. Plural forms checked per language (`[few]`, `[many]`, `[two]`).

**Tests**: `every_catalog_matches_english` over all 26; a catalog test that every plural message has the forms its language needs; the help builds in every language; each platform's UI test tours every language (main window, compose, Options, Add Mail Account, the key windows) with the checks the pseudo-language has (no English left, nothing cut off), screenshots of the longest ones (Finnish, Hungarian, Greek, Russian) for the review. The board post gets a comment inviting reviewers.

## 3. All Sent and All Drafts (#6)

Builds on the folder list that starts with the Inbox (`docs/folder-tree-plan.md`, its pull request first).

**The core**: the tree's rows gain All Sent and All Drafts after All Inboxes (two or more accounts), each with a row per account under it named after the account, the way All Inboxes has the Inboxes; the account headings lose Sent Items and Drafts. `Scope::AllSent` and `Scope::AllDrafts` (one rule: the folders of that special use, the store's own), listed with the To column and the Account column, sorted on an index (the query plan test covers them); the status bar counts them; All Drafts counts its drafts. Opening a draft from All Drafts opens the compose window from that draft's account. Next Unread, notifications and the tray count stay on the Inboxes.

**The apps** draw the rows as the core gives them (after the folder list change, nothing of their own), with the menus by kind (All Sent and All Drafts have none of a folder's commands).

**Tests**: the tree's rows with two accounts (and one, where nothing changes); the scopes' messages and counts; a draft from All Drafts reopened in its own account. UI tests: `all-sent-1-list`, `all-drafts-1-list`, `all-drafts-2-open`.

## 4. Opening attachments (#9)

**The core**:

- `attachment_kind(name, type)`: the word of a file's icon (image, PDF, document, spreadsheet, presentation, archive, audio, video, calendar, contact, key, text, other), and whether it can run code: one table for all three platforms (executables, installers, scripts, shortcuts, Office files with macros, disk images and other files that open as programs: .exe .msi .bat .cmd .com .scr .ps1 .vbs .js .jse .wsf .hta .lnk .url .reg .jar .app .pkg .dmg .iso .img .command .sh .desktop .appimage .docm .xlsm .pptm and the rest), tested row by row.
- `open_attachment(folder, uid, index)`: writes the file into a private folder (`private_dir`, 0700 on the Mac and Linux, under XDG_RUNTIME_DIR on Linux), named safely, marked as from the internet (Zone.Identifier on Windows, quarantine on the Mac), and returns its path for the app to open with the system (ShellExecute, NSWorkspace, `gtk::FileLauncher`); refused for a file that can run code, with words that say why and that Save is the way. A decrypted file: the first time, the app shows the core's note (kept as a setting once seen). Calendar invitations on Linux move into the same private folder.

**The apps**: the attachment strip under the header (reading pane and message window) replaces the paper clip's menu as the way to the files (the menu stays in the toolbar as now), each file an icon with its name and size; double-click or Enter opens, right-click has Open, Save As..., Save All...; a file that can run code shows Open greyed with the reason.

**Tests**: the kind table; a file written once, private, marked, never overwriting; a refused type; a decrypted attachment's note once; the cleaning of old folders. UI tests (the opening of the system is answered by the test hooks, nothing launches): `attach-1-strip`, `attach-2-open`, `attach-3-menu`, `attach-4-refused`, `attach-5-encrypted-note`, in a message window too, keyboard only once.

## How every pull request is done

As in the OpenPGP plan: the core and its tests first, then the C API, the three apps, the words in every language (drafts marked for review), the help, the UI test steps in `scripts/ui-e2e/SCENARIO.md` and each platform's test, the feature map entries; then:

1. **UX review until nothing is left**, from the screenshots of all three platforms, as a principal UX, mail app UI and product expert: light and dark, a narrow window, keyboard only, the longest languages; fix and look again.
2. **/simplify** over the changed code, with the maintainability check.
3. **/security-review** of the branch (for #1 and #9 especially: the setup file is untrusted input and carries secrets; opening attachments is the classic way in).
4. fmt, clippy, the tests, prettier, `scripts/check-shells.sh`; push, CI green, merge; the board post updated.

## The pull requests, in order

1. `feat: open attachments` (#9): the core's kinds and opening, the strip on three platforms.
2. `feat: All Sent and All Drafts` (#6): after the folder list change is merged.
3. `feat(core): the setup file` and `feat: export and import the setup` (#1).
4. `feat(i18n): every language from one list` (#2), then `feat(i18n): ...` three pull requests of seven languages each, catalogs and help.

They start after the OpenPGP plan and the folder list change are merged, unless you say otherwise. No release is cut: the translations wait for your review first.
