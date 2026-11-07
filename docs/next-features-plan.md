# Next features: plan

The plan for the next round of features, from the review of November 2026 (at 0.8.0). Twelve pull requests, each landing on Windows, the Mac and Linux at once, merged to master one after the other. `docs/next-features-overview.html` is the same plan as a page.

## Scope

| #   | Feature                                                                               | From     |
| --- | ------------------------------------------------------------------------------------- | -------- |
| 1   | Double-click (or Enter) opens a message in a window of its own                        | UX fix 1 |
| 2   | Sent Items, Drafts and the Outbox show To, not From                                   | UX fix 2 |
| 3   | Archive command; on Gmail it removes every label                                      | UX fix 3 |
| 4   | Empty Deleted Items and Empty Junk E-mail                                             | UX fix 4 |
| 5   | Keyboard reading: next/previous, next unread, Go to Folder, Find in This Message      | UX fix 5 |
| 6   | Conversations: grouped by default, a switch in Options, expand/collapse, Watch/Ignore | Tier 1   |
| 7   | Address book: contacts, groups, vCard and CSV, Add Sender, Select Recipients          | Tier 1   |
| 8   | Bounces explained: port of `bounce-classifier` and EmailEngine's bounce detection     | New      |

## Decisions taken

- **Gmail Archive removes every label.** On an account with `X-GM-EXT-1`, Archive fetches the message's `X-GM-LABELS` and removes `\Inbox` and every user label with `UID STORE -X-GM-LABELS`, so the message is left only in All Mail. The state labels `\Sent`, `\Draft`, `\Starred` and `\Important` stay (they are not folders the user filed it in). Undo adds the removed labels back.
- **PRs are merged by Claude once CI is green** and a design review round finds nothing left to improve; the next PR starts from the new master. You review afterwards, or stop the work at any point.
- **The proposed keys below are confirmed**, single-letter keys included (they work only while the message list has focus).
- **Bounces are marked in the message list too**, not only explained when opened (PR 12).
- **A conversation holds the messages of one folder** (as Outlook Express and Thunderbird do; All Inboxes threads each account's Inbox on its own). Search results stay a flat list.
- **The address book is local, with groups, vCard and CSV.** No CardDAV in this round.
- **The bounce model is embedded.** One model version is pinned in the repo (about 1.4 MB in the binary) and checked against the JS library.

## Defaults chosen (say if you want otherwise)

- **Archive elsewhere** moves to the account's `\Archive` folder. If the account has none, the first Archive creates `Archive` (with `CREATE ... USE (\Archive)` where the server offers `CREATE-SPECIAL-USE`). It is off in Archive itself, Drafts and the Outbox. No yearly subfolders.
- **Empty** asks first, naming how many messages go for good. It is on the folder's right-click menu and under Edit, only for Deleted Items and Junk E-mail. It can not be undone, and agents can not do it.
- **The To column** shows the first recipient and "+2" for more, and sorts by recipient. Search results and All Inboxes keep From.
- **The message window** has the main window's message toolbar (Reply, Reply All, Forward, Print, Delete, Archive, Junk) plus Previous and Next. It reuses the reading pane, with the same lockdown. A draft still opens as a message to finish.
- **Collapsed conversation rows**: Delete, Move, Archive, Junk, Mark Read and Flag act on every message of the conversation, as in Outlook Express and Thunderbird; Reply and Print act on its newest message. The row is bold if any message is unread and shows the count.
- **Sorting with conversations**: by Date or Received, conversations go by their newest message; by the other columns, by their first. Inside a conversation, the oldest comes first.
- **Watch and Ignore** live in the local store, keyed by the conversation's first Message-ID. A watched conversation has the glasses icon in a Watch column (as in Outlook Express), and its new mail always notifies. An ignored one is greyed, its new mail is marked read without a notification, and View > Hide Ignored Conversations (on by default) leaves it out.
- **Contact groups** complete by name in To, Cc and Bcc and put in the members' addresses, so the message shows who gets it.
- **The bounce explanation** is a card at the top of the reading pane, drawn by the core into the sanitized document (one implementation for all three apps, inline SVG with no script), not a native panel like the invitation.

## Keys

| Action                         | Windows and Linux                 | Mac                         | Source                                                        |
| ------------------------------ | --------------------------------- | --------------------------- | ------------------------------------------------------------- |
| Archive                        | `A` in the list, toolbar button   | `A` in the list, Ctrl+Cmd+A | Thunderbird, Apple Mail                                       |
| Next / previous message        | Ctrl+. / Ctrl+,                   | Cmd+] / Cmd+[               | Outlook Express (Ctrl+> without Shift)                        |
| Next unread message            | `N` in the list                   | `N` in the list             | Thunderbird (Outlook Express's Ctrl+U is Message Source here) |
| Go to Folder                   | Ctrl+Y                            | Cmd+Shift+Y                 | Outlook Express                                               |
| Find in This Message           | F3                                | Cmd+Option+F                | Outlook Express, Mail                                         |
| Expand / collapse conversation | Right / Left, `*` and `\` for all | the same                    | Outlook Express, Thunderbird                                  |
| Watch / Ignore Conversation    | `W` / `K` in the list             | the same                    | Thunderbird                                                   |
| Address Book                   | Ctrl+Shift+B                      | Cmd+Shift+B                 | Outlook Express                                               |

## 1. Quick UX fixes

### PR 1: `feat: the recipients column in Sent Items, Drafts and the Outbox` (S)

- Core: `pe-store` `SortField::To` (first recipient's name, then address), `Message` gives the list's To text, and the folder tells the apps which column it shows (`pe-core` decides from `\Sent` and `\Drafts`, not the apps).
- Apps: the From column's title and value come from the core; the column swaps when the folder changes.
- Tests: store sort by To; Sent Items listing in the UI tests (`main-3-sent-items` shows To).
- This PR also commits this plan and its overview, and the review marks for new translations with their check (below).

### PR 2: `feat: Archive` (M)

- `pe-imap`: `X-GM-LABELS` in FETCH and `UID STORE +/-X-GM-LABELS` (astring or modified UTF-7 labels, quoted as mailbox names).
- `pe-core`: `archive_messages(folder, uids)`. Gmail: fetch labels, remove `\Inbox` and the user labels, drop the message from the local Inbox and label folders at once (the next sync agrees). Others: move to `\Archive`, creating it when missing. Undo: Gmail restores the labels; others move back.
- The `archive` command in `commands.toml` (Message menu, toolbar between Delete and Junk, right-click menu). It works on several messages; agents get it with the organize permission.
- Tests: `pe-imap` parsing and command building; `e2e_core` against ImapKit with its `x-gm-ext-1` plugin (labels removed, state labels kept, Undo puts them back) and a plain server (folder made, message moved). Real Gmail once by hand.

### PR 3: `feat: Empty Deleted Items and Empty Junk E-mail` (S)

- `pe-core`: `empty_folder(folder)`: `STORE \Deleted` on 1:* and `EXPUNGE` (UIDPLUS not needed, since everything goes), local rows gone at once.
- Command `empty_folder` (folder right-click menu, Edit), with a confirmation that names the count (`pe-core/src/text.rs`).
- Tests: `e2e_core` empties both folders on ImapKit; UI tests take `organize-8-empty`.

### PR 4: `feat: a message in a window of its own` (M)

- Core: nothing new except `Selection` steps for Previous and Next in the list's order (shared with PR 5).
- Apps: Windows `message.cpp` (a top-level window around the `preview.cpp` reading pane), Mac `MessageWindow.swift`, Linux `message_window.rs`. Several can be open at once; each follows deletions and moves (closes or steps on).
- Tests: UI tests open a message with Enter, reply from the window, step with Next (`read-16-window`).

### PR 5: `feat: keyboard reading` (M)

- Commands: `next_message`, `previous_message`, `next_unread` (wraps into the next folder with unread mail, asking first, as Outlook Express does), `go_to_folder` (the Move dialog's folder tree with its filter box, reused), `find_in_message`.
- Find in This Message uses each web view's own find: WebView2 `ICoreWebView2Find` (check that the pinned SDK 1.0.4258 has it), `WKWebView.find(_:configuration:)`, WebKitGTK `FindController`. No script runs in the reading pane.
- Tests: core selection order with wrapping; UI tests for next unread, Go to Folder and Find (`read-17-find`).

## 2. Conversations

### PR 6: `feat(core): conversations in the store` (M, no UI)

- Fetch `BODY.PEEK[HEADER.FIELDS (REFERENCES)]` with every summary; a background pass fills it for messages already stored, newest first (as `fetch_texts` does). `In-Reply-To`, already stored, covers most replies meanwhile.
- Migration: `messages.references`, `messages.thread_id`, and an index on `(folder_id, thread_id)`.
- Threading per account in `pe-store/src/threads.rs`: union of Message-ID, References and In-Reply-To (JWZ without subject merging); on Gmail `X-GM-THRID` decides. References capped at the last 50 ids, ids normalized, cycles broken.
- `Scope` gains a threaded listing: one row per conversation in the folder (newest message, count, unread count, flags merged), with the expanded conversations' messages spliced in by the core. Paging stays offset and limit, so the apps' virtual lists do not change shape.
- Measure on the 489,000 message store used for All Inboxes; aim for under 20 ms for the first page of a 120,000 message folder, or keep a per-folder summary table.
- Tests: threading fixtures (missing parents, broken References, Gmail ids, a reply arriving before its parent), paging with expanded conversations, migration from the current schema.

### PR 7: `feat: conversations` (L)

- Options: "Group messages by conversation", on by default; View > Expand All Conversations and Collapse All.
- The list rows carry depth, whether they have children, and whether they are expanded. Each app draws an indent and a +/- button in the Subject column, as Outlook Express did: Windows through `LVIF_INDENT` and a state image in the owner-data list view, the Mac in its table cells, Linux in its `ColumnView` cells (no `TreeListModel`, since the core flattens). Right and Left expand and collapse.
- Actions on a collapsed row act on the whole conversation; Undo takes them back in one step.
- Tests: core actions on whole conversations; UI tests on all three (`threads-1-collapsed`, `threads-2-expanded`, `threads-3-options-off`).

### PR 8: `feat: Watch and Ignore Conversation` (S)

- Store table `thread_marks (account, root_message_id, watch|ignore)`; new messages inherit the mark when they arrive; notifications and Mark Read on arrival follow it.
- Message > Watch Conversation and Ignore Conversation; the Watch column; View > Hide Ignored Conversations.
- Tests: core rules on arrival; UI tests (`threads-4-watch`, `threads-5-ignore`).

## 3. Address book

### PR 9: `feat(core): the address book` (M, no UI)

- Store: `cards` (name parts, nickname, company, phones, notes, the vCard's other properties kept for export), `card_addresses`, `card_groups`, `card_members`. The table that completes addresses today stays as the list of recent people; completion ranks address book entries first.
- `pe-core/src/vcard.rs`: vCard 3.0 and 4.0 read and write (folding, escaping, charsets, several cards in a file, size limits, no PHOTO URLs followed). CSV import that knows the column names Outlook, Thunderbird and Google export.
- Tests: vCard round trips, the files of Thunderbird, Apple Contacts and Google, CSV variants, hostile input.

### PR 10: `feat: the Address Book` (L)

- Tools > Address Book: groups on the left, people on the right (Name, E-mail, Phone), toolbar New Contact, New Group, Properties, Delete, Write To; a find box.
- Contact Properties (names, several addresses with the default, phones, company, notes), Group Properties (name, members from the book or typed).
- "Add Sender to Address Book" on the message's right-click menu and in Tools.
- Compose: the To, Cc and Bcc labels become buttons that open Select Recipients (Outlook Express's picker); groups complete by name.
- File > Import > Address Book (vCard, CSV) and File > Export > Address Book (vCard).
- Tests: UI tests on all three (`contacts-1-book`, `contacts-2-person`, `contacts-3-group`, `contacts-4-pick`, `contacts-5-import`).

## 4. Bounces explained

### PR 11: `feat(core): pe-bounce` (M, no UI)

- A new crate, `pe-bounce` (`#![forbid(unsafe_code)]`):
    - `detect.rs`: port of `../emailengine/lib/bounce-detect.js` over `pe-mime`'s parse: RFC 3464 `message/delivery-status` (per recipient Action, Status, Diagnostic-Code, Remote-MTA), `X-Failed-Recipients`, the provider formats (Gmail, Exchange, Postfix, Exim, qmail, WorkMail, Zoho), a delay notice told from a failure, and the original message's headers. Its heuristics run only on mail from mailer-daemon or postmaster, or with `Auto-Submitted`, so ordinary mail that quotes an SMTP error is not taken for a bounce.
    - `classify.rs`: port of `../bounce-classifier/src/index.ts`: the tokenizer (ASCII `\w` as in JS, `(?-u:\w)`), the forward pass, the text and SMTP code rules over the model, the 0.5 threshold, retry timing and blocklist naming. 16 labels.
    - `model/`: `vocab.json`, `labels.json`, `config.json`, the 1.3 MB weights, built in with `include_bytes!` and read once. `scripts/update-bounce-model.sh` fetches a newer one and records its hash.
- Conformance like `pe-content`: `tests/fixtures/*.mjs` run the JS libraries (built checkouts) over `bounce-classifier`'s test inputs and EmailEngine's `test/fixtures/bounces/*.eml`, and `tests/conformance.rs` compares labels, scores (to 1e-5) and the fields found. EmailEngine's hostile input tests come along.
- Rust's regex engine runs in linear time, which removes the ReDoS care the JS code needs; the caps on input length and header blocks stay.

### PR 12: `feat: bounces explained in the reading pane` (M)

- `pe-core/src/view.rs` finds the bounce when a message is opened and gives the document a card: failed or delayed, each recipient with a plain explanation of the category and what to do (mailbox does not exist, mailbox full, blocked as spam, server listed on a blocklist and which, rejected by policy, greylisted or delayed with when it will retry, and so on), and the server's own words, escaped, folded under "Details". Six small inline SVG pictures cover the 16 labels (address, full mailbox, block, spam or virus, server or connection, clock).
- If the bounced message is in Sent Items (found by Message-ID), the card's link selects it.
- The words are in `core.ftl` (16 explanations, each with a "what you can do").
- In the list: the sync marks a message whose BODYSTRUCTURE is `multipart/report; report-type=delivery-status` (a migration adds `messages.bounce`, filled for stored mail from their cached structure), and the list shows an "undelivered" icon in the attachment column's place. The search takes `is:bounce`. Bounces found only by the heuristics get the icon once opened.
- Tests: `pe-html` card rendering and CSP; `view.rs` with each fixture; the store's `is:bounce` and the sync's marking against ImapKit; UI tests (`read-18-bounce`, `read-19-delayed`, `read-20-bounce-list`) on all three.

## How every PR is done

1. On master, `git pull`, then a branch (`feat/<name>`).
2. The core and its tests first: unit tests, migration tests, `e2e_core` against ImapKit for anything that talks IMAP.
3. `core/commands.toml` or the C API; rebuild `pe-ffi` and commit the header and the generated command tables.
4. The three apps.
5. **Translations**: English in `core/locales/en` (`core.ftl`, `app.ftl`, the platform files), then draft German, Estonian, Spanish and French following `core/locales/GLOSSARY.md`. Every draft is marked for your review, see "Marking new translations" below. `pe-i18n` tests (every catalog matches English, no dashes, mnemonics) must pass, and the pseudo-language run must show no English left over and nothing cut off.
6. **Help**: `help.html` and `help.{de,et,es,fr}.html`, the keyboard table included; `docs/shells.md` for new parts.
7. **UI end-to-end**: the step in `scripts/ui-e2e/SCENARIO.md`, in `scripts/ui-e2e.ps1`, `UITestSteps.swift` and `linux/src/e2e/`, and the screenshots in `scripts/feature-map.mjs`. Run `scripts/win-ui-e2e.sh`, `scripts/mac-ui-e2e.sh` and `scripts/linux-ui-e2e.sh`, look at the screenshots, and run `feature-map.mjs --check` for each platform.
8. **UX and design review, until nothing is left to improve**: for every change a user can see, look at the screenshots of all three platforms (in English and in the pseudo-language, light and dark where the platform has it) as a UX designer and a mail app product expert would: layout, alignment and spacing, wording, the order of controls and menu items, keyboard use, what a new user would expect, and how Outlook Express, Thunderbird and Apple Mail do the same thing. Write down what could be better, improve it, take the screenshots again and review again. Repeat until a round finds nothing left to improve, then note the rounds and what changed in the PR description. Improvements are committed as `fix(ux)` and keep to the platform's own look (classic on Windows, native on the Mac and Linux). The rounds run on the Mac and Linux screenshots; Windows is assumed to follow, see "The Windows build machine" below.
9. **/simplify** over the changed code, with the maintainability check (functions that grew, extractions that bring them back).
10. **/security-review** of the branch; fix what it finds.
11. `cargo fmt --all`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test --workspace`, prettier on changed Markdown and YAML, `scripts/check-shells.sh`.
12. Commits in the PR, in this order: `feat(core)`, `feat(windows)`, `feat(mac)`, `feat(linux)`, `feat(i18n)`, `docs(help)`, `test(e2e)`, then `fix(ux)` (design review), `refactor` (simplify) and `fix` (security review) as needed.
13. Push, open the PR, `gh run watch`. Fix real failures; rerun flaky jobs at most 3 times.
14. Merge with a merge commit (as the repo does) once CI is green and the last design review round found nothing to improve, without waiting for a review, then start the next PR from the updated master.

PR 11 touches only a new crate, so it can be built in a worktree alongside PRs 6 to 10 and merged in its turn.

## The Windows build machine

The connection to `andri@10.8.0.8` is unstable. SSH comes back after a while, but a dropped RDP session does not come back while you are away, and without an active desktop session the screenshots come out blank (`ssh andri@10.8.0.8 query user` says `Disc` instead of `Active`). So:

- **The UX review loop runs on the Mac and Linux screenshots.** Windows is assumed to look and behave like them, since the three apps share the core, the words and the layout decisions.
- **Windows is still built and tested.** `scripts/win-build.sh` and `scripts/win-test.sh` need only SSH; when SSH is down, wait and retry rather than skip, and CI builds and tests Windows on every push anyway.
- **Windows screenshots come from CI when the desktop is gone.** CI runs `scripts/ui-e2e.ps1` on its own Windows runner and uploads the screenshots as the `ui-e2e` artifact (`gh run download <run> -n ui-e2e`). Look at those for anything Windows-only (the classic controls, the toolbar strips, text cut off in the narrower Tahoma layout).
- **What could not be checked on Windows is logged** in `build/windows-ux-pending.md` (not committed, kept on the Mac across sessions): the PR, the screens and the checks still owed, and why (no RDP session, blank screenshots, SSH down). A failed `scripts/win-ui-e2e.sh` run is logged there too, with its log.
- **Windows does not hold up a merge** when CI's Windows jobs pass; only the review owed is logged.
- **When RDP is back** (`query user` says `Active`), rerun `scripts/win-ui-e2e.sh` for the logged items, review the screenshots the same way, fix what they show in a `fix(ux): windows ...` PR (with the rest of the routine above), and strike the items from the log. Check the log at the start of each PR, and once more at the end before the release.

## Marking new translations

The four languages had their native review at `097322f`. Everything translated after it is a draft, and you edit the drafts once all the PRs are in, so each one is marked where it is:

- **In the Fluent files**, the line `# review: new` right above a message that is new, or `# review: changed` above one whose English changed (the old translation may no longer fit). Fluent reads these as comments on the message; the build and the app ignore them.

    ```
    # review: new
    cmd-archive = &Archivieren
    ```

- **In the help pages** (`help.{de,et,es,fr}.html`), `<!--review-->` before and `<!--/review-->` after each new or changed passage, the way `<!--os:...-->` marks platform parts. `pe_help_page` drops them from the shown page.
- **`core/locales/REVIEWED`** holds the commit of the last native review (`097322f` to begin with).
- **`scripts/i18n-review.mjs`** lists what is waiting for review: each language, file and id with its English and the draft, and the marked help passages, as text or as an HTML page with English and the draft side by side. With `--check`, it compares every catalog with the commit in `REVIEWED` and fails when a message is new, or its English changed, without a mark; CI runs it, so no draft can go in unmarked.
- **When you have edited them**: remove the marks you have reviewed, and once none are left, put the current commit in `REVIEWED`. A message you edit but leave marked stays on the list.
- `GLOSSARY.md` describes the marks for whoever translates next.

## At the end

- Every PR merged to master; the release-please PR collects them as 0.9.0 and is left for you to merge.
- `build/windows-ux-pending.md` empty: every Windows check owed has been run on the build machine's desktop, or is listed for you with the reason it is still open.
- `node scripts/i18n-review.mjs --html build/i18n-review.html` gives you the list of every draft translation and help passage to edit, by language.
- The homepage screenshots refreshed with `scripts/homepage-screenshots.sh`, as a PR in `postalsys/inboxclassic.com`.

## Security notes, per feature

- Gmail labels come from the server: quoted as mailbox names, never put into a command unquoted.
- Empty can not be undone: it asks first, and agents can not call it (they never delete for good).
- Message windows and Find use the reading pane's lockdown; no script is enabled.
- References are remote data: capped, normalized, cycles broken, no quadratic work on hostile threads.
- vCard and CSV files: size caps, no URLs followed, no images fetched; the export writes vCard only.
- Bounces are remote data too: the server's words are escaped in the document, blocklist links go only to the known blocklists' own https pages (from the classifier's table), never to a URL from the message.
