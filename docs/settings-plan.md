# Settings in pages: the settings window refactoring plan

The review with the screenshots is in `settings-overview.html` beside this file. In short: the settings window has grown to 13 controls in one long column on every platform, in three different orders, with three sets of labels for the same things. None of the three follows its platform's pattern for a settings window (Windows: a tabbed property sheet; Mac: a toolbar of panes; GNOME: pages and titled groups). The plan puts the same 13 settings into the same three pages and the same groups on all three, each in its platform's form, so the help can describe one structure.

## What is there today

| Setting                           | Windows (Tools > Options)     | Mac (Inbox Classic > Settings) | Linux (Main Menu > Preferences) | Stored                                                    | Default           |
| --------------------------------- | ----------------------------- | ------------------------------ | ------------------------------- | --------------------------------------------------------- | ----------------- |
| Language                          | 1                             | 1                              | 1 (group 1)                     | app (registry `Language`, `AppleLanguages`, settings.ini) | system            |
| Notify of new mail                | 2                             | 3                              | 9 (group "New mail")            | app (`NewMailNotifications`)                              | on                |
| Sign-in codes in notifications    | 3 (indented)                  | 4 (indented)                   | 10                              | app (`CodesInNotifications`)                              | off               |
| Group by conversation             | 4                             | 5                              | 3 (group 2)                     | app (`GroupByConversation`)                               | on                |
| Layout                            | 5                             | 2                              | 2 (group 2)                     | app (`Layout`)                                            | Automatic         |
| Delay before sending              | 6                             | 11                             | 11 (untitled group)             | core store (`outbox.rs`)                                  | 10 s              |
| Senders' pictures in the list     | 7                             | 6                              | 4 (group 2)                     | app (`ListPictures`)                                      | on                |
| Dark background for messages      | none (always light, intended) | 7                              | 5 (group 3)                     | core store                                                | on                |
| Download pictures in all messages | 8                             | 8                              | 6 (group 3)                     | core store                                                | off               |
| Trusted Senders (dialog)          | 9 (button)                    | 9 (button, sheet)              | 7 (row, subpage)                | core store                                                | empty             |
| Open .eml files (action)          | 10 (button)                   | 10 (button)                    | 12 (button row)                 | system                                                    |                   |
| Download messages in advance      | 11                            | 12                             | 13 (group "Downloading")        | core store (`download.rs`)                                | Recent up to 1 MB |
| Storage limit per account         | 12                            | 13                             | 14                              | core store                                                | 1 GB              |

Code: `app/src/options.cpp` (one 220 line `OptionsDialog`), `mac/Sources/InboxClassic/Settings.swift` (one `NSGridView` of 18 rows), `linux/src/preferences.rs` (one `AdwPreferencesPage`, seven groups). App preferences are each app's own (`app/src/main.cpp`, `mailbox.cpp`; `AppDelegate`; `linux/src/settings.rs`) and travel in a setup file by the names of `pe-core/src/setup/mod.rs` `PREFERENCES`; the rest are in the core's store.

The defaults are sound and stay: notifications on, codes off (a lock screen shows notifications), grouping on, pictures off, dark messages on, a 10 second wait before sending, recent mail downloaded ahead, 1 GB per account.

## Findings

### High

1. **One long, unstructured column on all three.** Windows: 13 controls between four etched lines, 605 px tall at 100% and 620 px in the pseudo-language (`build/ui-e2e/options-1-language.png`, `lang-4-pseudo-options.png`). Mac: 18 grid rows in a 610 x 660 pt window with no headings (`build/ui-e2e-mac/options-1-language.png`). Linux: seven groups of which only two have titles, and the Downloading group needs scrolling at 600 x 700 (`build/ui-e2e-linux/download-1-options.png`). Nothing tells the user which settings belong together, and the window will only get longer as settings are added.
2. **None follows its platform's settings pattern.** Windows has no tabs (Outlook Express Options: General, Read, Send, Compose, ... with OK, Cancel, Apply). The Mac window has no toolbar of panes and is always titled "Settings" (`Settings.swift:136-146`), where the HIG wants panes, the window titled by the pane and the last pane remembered. Linux uses `AdwPreferencesDialog` but with one page, so it has neither the view switcher nor meaningful groups (`preferences.rs:132-147`).
3. **Three different orders, so the help cannot describe one window.** Layout is 5th on Windows and 2nd on the Mac; Notify is 2nd on Windows, 3rd on the Mac and 9th on Linux; Delay before sending is 6th on Windows and 11th elsewhere (`options.cpp:375-467`, `Settings.swift:265-284`, `preferences.rs:132-139`). The help topic about the window (`help/en/options-language.html`) lists only 6 of the 13 settings, and 10 other topics repeat the three-platform path to the window in `<!--os-->` blocks.
4. **Windows keyboard access: 9 of 13 controls have no access key.** Only "Show Inbox Classic in", "Notify" and "Group" are underlined (`options-1-language.png`). `ui-layout-label`, `ui-send-delay`, `ui-codes-in-notifications`, `ui-list-pictures`, `ui-pictures-always-option`, `ui-trusted-senders-button`, `ui-eml-default`, `ui-download-ahead` and `ui-download-limit` have no `&`. A classic dialog is expected to be fully usable with Alt+letter.

### Medium

5. **Mixed commit model on Windows.** The dialog is OK/Cancel, but Trusted Senders' Remove and "Open .eml Files" take effect at once and Cancel does not undo them; there is no Apply (`options.cpp:243-250`, `RemoveTrusted`).
6. **A dependent option is never disabled.** "Show sign-in codes in new mail notifications" stays enabled with notifications off on all three (`options.cpp:399`, `Settings.swift:173`, `preferences.rs:71`). Windows and the Mac indent it, which promises the dependency, then do not keep it.
7. **"Show senders' pictures in the message list" does nothing in the Classic layout,** and neither the label nor its note says so (`ui-list-pictures-note`); only the help says "in the column layout". Someone in Classic who turns it on sees no change.
8. **Mac alignment is ragged.** Language and Layout have right-aligned labels in the label column, but "Wait before sending", "Download messages in advance" and "Storage limit per account" put their labels in the control column (`Settings.swift:237-247`, visible in `dark-6b-settings.png`); two push buttons sit in the middle of the check boxes.
9. **Linux groups are uneven.** The sending group has a description but no title, so the note floats between groups; "Open .eml Files with Inbox Classic" is a bold button row alone in its own group and reads like the dialog's main action; Language is an inline combo while every other choice row shows its value as a subtitle (`preferences.rs:47-52`, `253-271`; `download-1-options.png`).
10. **Long translations widen Windows and the Mac without limit.** Windows sizes the dialog to its longest check box text (`options.cpp:350-355`); Mac check boxes do not wrap, and the German `ui-dark-messages` is 95 characters. Linux wraps correctly (`tour-de-5-preferences.png`).
11. **One concept, three ids.** Notify: `win-options-notify`, `mac-notify-new-mail`, `gtk-notify-new-mail` (and `cmd-notify` in the menu). Language: `win-options-language-label`, `mac-language-label`, `gtk-language`. The restart question: `win-restart-ask`, `mac-restart-question`, `gtk-restart-to-change`. The restart note: `win-options-restart-note`, `mac-restart-hint`. Each costs translation and forces `<!--os-->` blocks in the help.
12. **The restart is told three ways.** Windows shows a note and asks after OK (naming the language); the Mac shows the same note and asks the moment the pop-up changes; Linux has no note and asks at once. All three are acceptable for their commit model, but the words should be the same.
13. **Default apps are split.** "Make Default Mail App..." is in the Tools menu only; "Open .eml Files with Inbox Classic" is in settings only. Outlook Express had both on its General tab ("Default Messaging Programs"), Apple Mail has "Default email reader" in General, Thunderbird has "System Integration" in General.

### Low

14. **The screenshots are stale.** The Mac ones show "Wait before sending" and "when the system is dark", strings replaced in the translation review (`b19a8950`). Refresh them in this work.
15. **Trusted senders title** is sentence case (`ui-trusted-senders-title`) on the Windows dialog's title bar, next to the Title Case button "Trusted Senders...". Acceptable; leave it, as it is shared with Linux where sentence case is right.
16. **`ui-list-pictures` uses a straight apostrophe** ("senders'"), the other strings use ’. English only.
17. **The export splits "Settings" and "Window preferences"** by where a value is stored, not by what the user sees in the window (Notify and Layout are "window preferences", Delay before sending is a "setting"). Not part of this plan; noted for later.

### Fine as it is

- Layout and Notify duplicate View > Layout and Tools > Notify of New Mail. Keep both: the menu is the quick switch, settings is where people look.
- Text Size, Hide Read Messages and Hide Ignored Conversations stay in the View menu (Outlook Express kept view toggles there too).
- Nothing in the window is really per account. "Storage limit per account" is one value applied to each account; a per-account override would belong in account Properties, not here.
- Windows has no dark message option because the Windows app is always light (`preview.cpp:69`, `255`). The help says so in a Mac and Linux part.
- F1 and the help buttons open `options-language` (`topics.toml [context] options`).

## Target structure

The same three pages, the same groups, the same order on all three. The help names pages and controls, never groups, so the Mac (which has no group headings, as Apple's own panes) can follow it too.

### 1. General

| Group        | Controls                                                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| Language     | Language [list], with the restart note                                                                                         |
| New Mail     | Notify me when new mail arrives; Show sign-in codes in new mail notifications (under it, disabled while notifications are off) |
| Sending      | Delay before sending [list], with its note                                                                                     |
| Default Apps | Make Default Mail App...; Open .eml Files with Inbox Classic                                                                   |

### 2. Reading

| Group        | Controls                                                                                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Message List | Layout [list]; Group messages by conversation; Show senders' pictures in the message list, with its note (says the column layout)                           |
| Messages     | Show messages on a dark background when the system is in dark mode (Mac and Linux); Download pictures in all messages, with its warning; Trusted Senders... |

### 3. Downloading

| Group                         | Controls                                                                        |
| ----------------------------- | ------------------------------------------------------------------------------- |
| (none, the page is the group) | Download messages in advance [list]; Storage limit per account [list]; the note |

### Windows: a classic property sheet

- One `WC_TABCONTROLW` (as `help.cpp` already uses, classic look, no Common Controls 6) with General, Reading, Downloading; under it `BS_GROUPBOX` frames titled by the groups; OK, Cancel, Apply at the bottom right. Apply is disabled until something changes and applies without closing; the language question comes after OK or Apply, as now.
- Every control stays a direct child of the dialog, shown or hidden with its tab, so `GetDlgItem` and the `IDC_OPTIONS_*` ids keep working for `scripts/ui-e2e.ps1`; a new `IDC_OPTIONS_TABS`.
- Ctrl+Tab, Ctrl+Shift+Tab and Ctrl+PageDown/PageUp switch tabs; Tab moves from the tab strip into the page. Every control has an access key, unique within its page with OK, Cancel and Apply.
- A fixed content width (about 380 DLU-equivalent, `Scale(400)`), check boxes `BS_MULTILINE` with their height measured, so a long translation wraps instead of widening the dialog; the height is that of the tallest page. Expected size about 430 x 400 at 100%, like Outlook Express's Options.
- `OptionsDialog` splits into one builder per page and the apply step (`ApplyOptions`), which also brings the function's size down (maintainability).
- Trusted Senders and the two default app buttons open their own windows and act there, as now; their `...` says so.

### Mac: a settings window with panes

- `NSToolbar` with `toolbarStyle = .preference` and three selectable items (SF Symbols `gearshape`, `eyeglasses` as Apple Mail's Viewing pane, `arrow.down.circle`); the window is titled by the pane, resizes with an animation to the pane's fitting height, and opens on the last pane chosen (`UserDefaults` `SettingsPane`). No OK button; every change counts at once, as now.
- Each pane is an `NSGridView`: labels of pop-ups right aligned in the first column (all of them, fixing finding 8), check boxes in the second; groups separated by extra space as Apple's panes do; push buttons at the end of their group. A content width of 480 pt, check box titles wrapping (`cell.wraps`, `preferredMaxLayoutWidth`) for long translations.
- The help button stays in each pane's bottom right corner; Cmd+, opens the window on the last pane, Cmd+W closes it.
- The language question stays at once on choosing (instant apply), with the shared words.

### Linux: AdwPreferencesDialog with pages

- Three `AdwPreferencesPage`s with title and icon (`emblem-system-symbolic`, `mail-read-symbolic`, `folder-download-symbolic`; check they are in the Docker image's theme), which gives the view switcher and keeps search. Every group titled; notes as group descriptions or row subtitles as now.
- Default Apps: two `AdwButtonRow`s, not a lone bold row. Every choice row in the same style (the value as subtitle, `choice_row`), the language too, using the existing `whole_names` factory for the popover.
- The codes row bound to the notify row's `active` as `sensitive`.
- No fixed `content_height(700)`; the pages are short enough for the natural height.

## Words

The aim is few new strings, and moving one concept to one id with the translations carried over (no review needed where the text does not change).

### New ids (drafts in every language, `# review: new`)

| Id                         | English          |
| -------------------------- | ---------------- |
| `ui-settings-general`      | General          |
| `ui-settings-reading`      | Reading          |
| `ui-settings-sending`      | Sending          |
| `ui-settings-default-apps` | Default Apps     |
| `ui-settings-message-list` | Message List     |
| `ui-settings-messages`     | Messages         |
| `ui-apply`                 | &Apply (Windows) |

Reused as they are: `ui-download-heading` (the Downloading page), `cmd-default-app` (the button), `ui-trusted-senders-*`, `ui-download-*`, `ui-send-delay*`, `ui-layout-label`, `ui-group-by-conversation`, `ui-dark-messages`, `ui-pictures-always-*`, `ui-eml-default`, `ui-options-system-default`, `ui-restart-now`, `ui-restart-later`, `gtk-language-subtitle`.

### Ids merged, translations carried over by a script (no review where noted)

| New id                                                                              | From (kept)                          | Removed                                         | Review              |
| ----------------------------------------------------------------------------------- | ------------------------------------ | ----------------------------------------------- | ------------------- |
| `ui-settings-new-mail` = New Mail                                                   | `gtk-new-mail-group`                 | `gtk-new-mail-group`                            | English only (case) |
| `ui-notify-new-mail` = &Notify me when new mail arrives                             | `win-options-notify`                 | `mac-notify-new-mail`, `gtk-notify-new-mail`    | no                  |
| `ui-restart-ask` = Inbox Classic shows { $language } once it restarts. Restart now? | `win-restart-ask`                    | `mac-restart-question`, `gtk-restart-to-change` | no                  |
| `ui-restart-note` = Restart Inbox Classic to change the language.                   | `win-options-restart-note`           | `mac-restart-hint`                              | no                  |
| `ui-language-label` = &Language:                                                    | `mac-language-label`, with `&` added | `win-options-language-label`, `gtk-language`    | yes (the `&`)       |

Linux strips the colon with `field_title` and every app strips `&` as now.

### Changed values (review in every language)

- Access keys added, English placement unique within each page: `ui-send-delay` "Delay before &sending:", `ui-codes-in-notifications` "Show sign-in &codes in new mail notifications", `ui-eml-default` "Open .&eml Files with Inbox Classic", `ui-layout-label` "&Layout:", `ui-list-pictures` "Show senders’ &pictures in the message list" (also the apostrophe), `ui-pictures-always-option` "Download pictures in &all messages", `ui-trusted-senders-button` "&Trusted Senders...", `ui-download-ahead` "&Download messages in advance:", `ui-download-limit` "&Storage limit per account:". `cmd-default-app` keeps "Make &Default Mail App...".
- `ui-list-pictures-note`: "In the column layout, shows brand logos or Address Book pictures for verified senders, and initials when no picture is available. Logos are downloaded once per brand, rather than for each message." (finding 7)

A new core test checks, in every language, that the access keys of each Windows page are unique (with OK, Cancel, Apply), and fails a translation that collides.

## In the core

- **`core/settings.toml`**: the pages, their groups and their settings in order: each setting's id, kind (switch, choice, button), label and note ids, platforms (`dark_messages`: mac, linux), and `depends_on` (`codes_in_notifications` on `notify_new_mail`). pe-ffi's `build.rs` generates `core/include/settings.h`, `mac/Sources/InboxClassic/Generated/Settings.swift` and `linux/src/generated/settings.rs` as it does the commands; CI checks they match. Each app lays out the pages and groups from it and builds each setting in one exhaustive switch, so a new setting fails the build of an app that does not show it, and the order cannot drift again. `scripts/check-shells.sh` counts `settings.toml` with `commands.toml`. The tests above (ids exist in the English catalog, access keys unique per page) read it too.
- **`pe-html` `help.rs`**: `<b data-settings="reading"></b>` writes the path to a page for each platform: Tools > Options > Reading, Inbox Classic > Settings > Reading, Main Menu > Preferences > Reading. Documented in `help/FORMAT.md`.
- No setting moves between the core's store and the apps' preferences.

## Help

- `options-language.html` (keep the id, its file in every language and the `[context]`): one section per page, every setting with what it does and its default; the dark option in a `<!--os:mac,linux-->` part. Title "Settings" in every language.
- `brand-logos`, `conversations`, `default-mail-program`, `download-ahead`, `drafts-outbox`, `layouts`, `new-mail`, `pictures-tracking`, `sign-in-codes`: the triple `<!--os-->` path replaced by `data-settings` with the page, mechanically in every language. `new-mail` and `options-language` lose their `<!--os-->` blocks for the notify and language labels (one id now).
- Translations of the changed topics marked for review.

## UI tests

- `scripts/ui-e2e/SCENARIO.md` steps 46 (Options and the language), the Undo Send step, conversations, sign-in codes, pictures, downloading, list pictures and dark messages: say which page each control is on; add: the codes control is disabled while notifications are off; the Mac window is titled by its pane and opens on the last one; Windows Apply applies without closing.
- Screenshots on all three: `options-1-language` becomes the General page, `options-2-reading` (new) the Reading page, `download-1-options` the Downloading page; `pictures-3-options` stays the trusted senders list. Linux `tour-<lang>-5-preferences` per page, Windows `lang-4-pseudo-options` per tab, for long translations.
- `scripts/ui-e2e.ps1`: a helper that selects a tab (`TCM_SETCURSEL` and the `TCN_SELCHANGE` notification) before each step; Mac `UITest*.swift`: `SettingsWindow.current?.select(.reading)`; Linux `e2e/steps.rs`: `set_visible_page_name`.
- `scripts/feature-map.mjs`: the "how" texts name the page (Options > Reading); the new screenshot.

## Order of work, one pull request

1. Core: `settings.toml`, its generation and tests; `data-settings` in `help.rs` with tests; the catalog changes (English, then the carried and drafted values in every language).
2. Windows `options.cpp`, split per page, and the `app.h` id.
3. Mac `Settings.swift`.
4. Linux `preferences.rs`.
5. Help: `options-language` and the path replacements, English then every language.
6. UI tests, SCENARIO, feature map; run all three and refresh the screenshots (they are stale today).
7. UX review of every page from the screenshots, on all three, in English, German, Finnish and the pseudo-language; fix and recheck until nothing is left.
8. `/simplify`, Prettier on the Markdown, the test suites; the homepage screenshots of the settings window if it shows one.

## Decisions for the product owner

1. **Three pages, or four with Sending on its own.** Recommendation: three. Sending has one control today; a page of one control looks unfinished. Give it its own page when a second sending option arrives (the group simply moves).
2. **The page names.** Recommendation: General, Reading, Downloading (Outlook Express's words where it had them; Downloading already translated). Alternative for the third: Storage.
3. **Make Default Mail App in settings too.** Recommendation: yes, in General > Default Apps, and keep it in the Tools menu.
4. **Apply on Windows.** Recommendation: yes, as Outlook Express's Options; it is the convention of a classic property sheet.
5. **Generate the structure from `core/settings.toml`, or build it by hand in each app in a documented order.** Recommendation: generate. It is the commands pattern the project already trusts, and it is what keeps three orders from drifting apart again.
6. **One id for the notify, language and restart words on all three** (Linux's "Notify of new mail" becomes "Notify me when new mail arrives"). Recommendation: yes; it removes six ids and most of the help's `<!--os-->` blocks.
7. **Mac only: "Check for updates automatically"** in General, bound to Sparkle's `automaticallyChecksForUpdates` (one new id). Recommendation: yes, in a later change; Mac apps usually have it, and today only Sparkle's first-run question sets it.

### Decided (2026-11-16)

1. Three pages.
2. General, Reading, Downloading.
3. Make Default Mail App in General > Default Apps, and still in the Tools menu.
4. Windows gets Apply; Cancel undoes everything, Trusted Senders and the .eml association included.
5. Generated from `core/settings.toml`.
6. One id each for the notify, language and restart words on all three.
7. The Mac's "Check for updates automatically" is in this refactor, in General.
