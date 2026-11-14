# Safe sending, rules and comfort: plan

The plan for the round of features chosen from the review of 14 November 2026 (at 0.17.1). Ten pull requests, each landing on Windows, the Mac and Linux at once, merged to master one after the other. `docs/sending-rules-comfort-overview.html` is the same plan as a page.

## Scope

| #   | Feature                                                                         | PRs  | Size |
| --- | ------------------------------------------------------------------------------- | ---- | ---- |
| 1   | Drafts saved automatically, and restored after a crash                          | 1    | M    |
| 2   | Undo Send: a sent message waits a few seconds in the Outbox                     | 2    | M    |
| 3   | "Did you forget the attachment?"                                                | 3    | S    |
| 4   | Text Size in the View menu, no keys                                             | 4    | S    |
| 5   | Flagged: one folder with the flagged messages of every account                  | 5    | M    |
| 6   | Send from another address                                                       | 6    | M    |
| 7   | Message Rules: a search query and the actions for new mail that matches it      | 7, 8 | L    |
| 8   | Messages in dark mode on the Mac and Linux                                      | 9, 10 | L   |

Not in this round: Block Sender, saved searches, Send Later (the review's 4, 9 and the other half of 10).

## Decisions taken (from the request)

- **A rule is a search query plus actions.** The rule editor's condition is the search box's own syntax (`from:`, `subject:`, `has:attachment`, words, `OR`, `-`), matched by the same code that searches. There is no second condition language.
- **A search offers to become a rule.** The bar over the search results gets "Create Rule…", which opens the rule editor with the query filled in.
- **Text Size has no keys**, so nobody changes it by accident and then can not find the way back. For the same reason the accidental ways in are closed: Ctrl+wheel in WebView2 and pinch zoom in the web views.
- **Flagged only.** No saved searches yet; the Flagged folder is built so that a saved search can later be one more row of the same kind.

Confirmed on 14 November 2026:

- **Rules run on new Inbox mail only**, with the opt-in "Also apply it to the messages already in the Inbox".
- **Mail a rule moves to a folder is still announced**, unless the rule has "Do not notify"; mail a rule marked read, junked or deleted is silent.
- **A rule's query refuses `in:` and the date terms**, and **`list:` is added** to search and rules.
- **Three ways to make a rule**: Tools > Message Rules, "Create Rule…" on the search results bar, and Message > Create Rule from Message.
- **Undo Send waits 10 seconds**, with Off, 5, 10, 20 or 30 in Options.
- **Closing a message keeps asking**; "Don't Save" removes a copy only the automatic saving made.
- **Dark messages on the Mac and Linux only**; Windows keeps the classic light look.
- **The work starts when you say go**, not before (another session is working in this checkout); each PR is then built in a git worktree of its own.

## Details of each feature (the smaller defaults; say if you want otherwise)

### Drafts saved automatically

- **Two layers, one behaviour.** A recovery copy in the local store 3 seconds after the last change (cheap, works offline), and the copy in the account's Drafts on the server once typing has stopped for 10 seconds, at most every 30 seconds while typing goes on. The second is the existing `save_draft`, so the status bar's "Saved in Drafts 14:02" needs nothing new.
- **Nothing is saved before the user changes something.** An untouched reply or an empty new message leaves no draft.
- **Closing still asks** when there are changes since the last save. "Don't Save" removes a copy that only the automatic saving made; a draft the user saved themselves, or opened from Drafts, stays as it was last saved.
- **After a crash**, the next start opens the messages that were being written again, each with a line saying it was restored. Recovery copies go when their window closes or the message is sent.
- **Large messages**: over 5 MB with attachments, the server copy is saved only every 2 minutes; the recovery copy keeps the paths of the attached files, not their bytes.
- No setting.

### Undo Send

- **10 seconds by default.** Options gets "Wait before sending: Off, 5, 10, 20 or 30 seconds".
- **It is the existing Undo.** Send closes the window; the status bar (Windows), a bar under the message list (Mac) or a toast (Linux) says "Sending in 10 seconds" with an **Undo** button, and Edit > Undo reads "Undo Send" (Ctrl+Z, Cmd+Z) until the message goes. After that it is greyed again.
- **Undo opens the message again** as it was, attachments included, from the Outbox entry (`compose::reopen`), and takes it out of the Outbox.
- **Quitting sends.** Exit, or a system shutdown, sends what is waiting right away rather than drop or keep it; without a connection it stays in the Outbox as today.
- The Outbox window lists a waiting message with "Sends in 8 seconds". Agents' messages keep their own 30 seconds and approval.

### The attachment reminder

- Only when the message has no attachment, and only in what the user wrote: the subject and the text above the signature and the quoted message.
- The words of all five languages are checked whatever the language of the windows is (people write in more than one): "attached", "attachment", "enclosed", "im Anhang", "angehängt", "manuses", "lisatud", "adjunto", "ci-joint", "pièce jointe" and their forms, as whole words.
- The question names the word found: "You wrote “attached”, but no file is attached." **Go Back** (default) and **Send Anyway**. No setting.

### Text Size

- View > Text Size > Smallest, Smaller, **Medium**, Larger, Largest, a radio group as in Outlook Express (80, 90, 100, 120, 140 percent). The check mark always shows where it is and Medium is one click away.
- It applies to the reading pane, message windows and the text being written (how it is shown, not how it is sent). Print and the help keep their size. It is remembered.
- No keys, no Ctrl+wheel, no pinch.

### Flagged

- A **Flagged** row under All Inboxes, always there (also with one account), with the number of flagged messages beside it, not bold.
- It lists every flagged message of every account, with the Folder column that search results have. Deleted Items and Junk E-mail are left out. On Gmail a message shows once (not again from All Mail or Starred), as search does.
- A message whose flag is taken away stays listed until another folder is chosen, the way "unread only" keeps a message just read.
- Every command works on its messages in their own folders. New mail can not arrive there, so it never notifies.

### Send from another address

- Account Properties gets **Other addresses**: a list with Add, Edit and Remove; each has an address and a name. The account's signature is used for all of them (a signature per address can come later).
- The From list of a message shows them under their account: `Name <alias@example.com>`.
- **A reply goes from the address the message was sent to**, when that is one of the account's addresses. Reply All leaves all of the account's own addresses out of the recipients.
- The address is used for the From header and the SMTP envelope. A server that refuses it gets a plain explanation ("The server of Work does not let you send as alias@example.com"). The help says that Gmail needs the address under "Send mail as" first.
- Sent Items' To column, "from me" in conversations and the Address Book's Add Sender know the other addresses too.

### Message Rules

- **Tools > Message Rules**: the list of rules in their order, each with a check box (on or off), and New, Edit, Delete, Move Up, Move Down.
- **The rule editor**, one window:
    - Name (filled in from the query, can be changed).
    - "For new mail in the Inbox of": All accounts, or one.
    - "that matches": the query, with a line under it that says how many messages now in the Inbox match, and **Show** to see them in the main window.
    - "do this": check boxes for Move to folder (with the folder picker of Move), Mark as read, Flag (with the color), Archive, Move to Junk E-mail, Delete (to Deleted Items), Do not notify.
    - "Also apply it to the messages already in the Inbox", off by default.
- **Three ways in**: Tools > Message Rules > New; "Create Rule…" on the search results bar; Message > Create Rule from Message (also on the right-click menu), which fills in `from:` with the sender, or `list:` for a mailing list.
- **When rules run**: on mail that arrives in an Inbox after the rule was made, on this computer, while Inbox Classic runs (it keeps running in the tray). Not on the first sync of an account. The help says so, and that the provider's own filters are the way to sort mail when the computer is off.
- **Order**: every matching rule applies, top to bottom; a rule that moves the message away (Move, Archive, Junk, Delete) is the last one for it.
- **Notifications**: a message a rule marked read, deleted or junked is not announced; one moved to a folder is, and clicking opens it there.
- **What a rule's query may hold**: everything the search takes except `in:` (the rule already names where) and the dates (`before:`, `after:`, `older_than:`), which the editor refuses with a reason. One new operator for search and rules alike: `list:` matches the List-ID.
- **Words in the text**: a rule that looks for words in the body needs the text of a new message before it can decide. The worker fetches the text parts of the new messages first (the existing `fetch_texts`, for those UIDs only), then matches.
- **No forwarding, no replying, no deleting for good**: a rule can not send anything anywhere or lose mail. **Agents can not make, change or run rules.**
- Rule actions are not on the Undo stack (they happen while the user is not looking); the status bar says "2 messages sorted by your rules" and the rule's name is in Message Properties of a message it handled.

### Messages in dark mode

- **The Mac and Linux follow the system**; Windows keeps the classic light look.
- **Plain text messages, the cards (bounce, code, invitation, unsubscribe), the fold button and the "downloading" pages** get real dark styles.
- **HTML messages**, decided in Rust while sanitizing:
    - a message that brings its own dark styles (`color-scheme`, `prefers-color-scheme`) is shown as it asks;
    - a message that sets no backgrounds (what people write in Gmail, Outlook and Apple Mail) is shown dark, and text colors too dark to read on it are lightened;
    - a message with its own backgrounds or a style sheet that colors it (newsletters, receipts) is shown as designed, light, as Apple Mail does.
- **Writing**: the editor is dark too. Nothing about colors is added to what is sent: text without a color is sent without one.
- **One switch** in Options on the Mac and Linux: "Show messages on a dark background when the system is dark", on by default. Print is always light.
- The web views get a dark background before a document loads, so nothing flashes white.

## The pull requests

Each PR follows "How every PR is done" below. Screenshot names are the UI tests' new steps.

### PR 1: `feat: drafts saved automatically` (M)

- Core: `pe-store` migration `compose_recovery` (id, account, the `Outgoing` as columns, attachment paths, kind, saved time). `pe-core/src/compose.rs` gets the policy (`Autosave`: fed "changed" and "tick", answers "save recovery" or "save draft", with the times above) so the three apps do not each carry the rules. `Core::recovered()` lists what a crash left; `Core::compose_closed(id)` clears a copy; "Don't Save" removes an automatic-only draft from Drafts (by its Message-ID, as sending does).
- C API: `pe_compose_changed`, `pe_compose_due`, `pe_recovered` (a list handle) and `pe_compose_closed`.
- Apps: the compose windows report changes (the editor's `dirty` already arrives), run one timer and save when the core says so; at start they open what `pe_recovered` lists.
- Tests: unit tests of the policy with a fake clock; migration test; `e2e_core` against ImapKit (automatic save lands in Drafts once, replaces itself, "Don't Save" removes it, a draft opened from Drafts survives "Don't Save"); offline save keeps the recovery copy. UI tests: type, wait, see "Saved in Drafts" without pressing Save (`write-20-autosave`); kill the app while writing, start it, the message is back (`write-21-restored`).
- This PR also commits this plan and its overview.

### PR 2: `feat: Undo Send` (M)

- Core: the user's `send` puts `not_before = now + delay` on the Outbox entry (the column and the worker's wait exist for agents). `Core::undo_send(id)` takes the entry out if it has not gone and gives the `Draft` to open (`compose::reopen` on the stored message). The Undo stack gets a `Send` entry that expires when the message goes. `Event::SendWaiting { id, seconds, subject }` and the words in `text.rs`. Exit flushes (`clear_not_before`, which exists). The delay is a preference the core keeps.
- C API: `pe_undo_send`, the delay in the preferences calls; the `undo` command's label already comes from the core.
- Apps: the Undo button where the "Sent" words show today; the Options row; the Outbox row's "Sends in N seconds".
- Tests: store and core tests of the race (undo just before and just after it goes: either the window comes back or the message is sent, never both, never neither); `e2e_core` (nothing reaches ImapKit's SMTP before the delay; undone, nothing ever does; attachments come back; the draft copy stays in Drafts after undo and goes after sending). UI tests: `write-22-undo-send`, `write-23-undone`, `options-3-send-delay`. The existing tests that send run with the delay off, except the ones for this.

### PR 3: `feat: a reminder when an attachment is missing` (S)

- Core: `pe-core/src/attachment_words.rs`: the words per language from the catalogs, matched as whole words, case and accents folded, in the subject and the written text only (the signature and the quote cut off the way `outgoing_html` already knows them). `compose::check` gains a soft finding, `ComposeWarning::NoAttachment { word }`; `send` takes `confirmed: bool`.
- Apps: one question before sending, default Go Back.
- Tests: unit tests per language, quoted text and signatures ignored, "attached" inside another word ignored, a message with a file never asks. UI tests: `write-24-attachment-reminder` (asks, Go Back keeps the window, Send Anyway sends).

### PR 4: `feat: Text Size` (S)

- `commands.toml`: `text_size_smallest` … `text_size_largest` in a View > Text Size submenu, radio, no keys. The core keeps the preference and gives the factor.
- Apps: WebView2 `ZoomFactor` (and `IsZoomControlEnabled(FALSE)`, pinch off), `WKWebView.pageZoom` (magnification off), WebKitGTK `zoom-level`; applied to the reading pane, message windows and the editor, and again when a window opens.
- Tests: UI tests set Larger, check the factor the web view reports and the check mark, restart and find it kept, set Medium (`read-30-text-size`). A check that Ctrl+wheel no longer changes it on Windows.

### PR 5: `feat: the Flagged folder` (M)

- Core: `pe-store` `Scope::Flagged` (flagged, not in `\Trash` or `\Junk`, one row a Gmail message) with count, paging, neighbours and next unread as the other scopes have; the "stays listed until you leave" set, shared with unread only; the row and its count from the core (`text.rs`), events when the count changes.
- Apps: the row under All Inboxes with a flag icon (Fluent's, through `build-icons.sh` on Windows), the Folder column, the empty state ("No flagged messages. Flag a message to find it here.").
- Tests: store tests (several accounts, Gmail duplicates, Trash and Junk left out, the count); `e2e_core` flags on ImapKit and sees it listed, unflags from another client and sees it go; UI tests `main-10-flagged`, `main-11-flagged-empty`, unflag stays until leaving.

### PR 6: `feat: send from another address` (M)

- Core: migration `account_addresses (account_id, email, name, position)`; `AccountSettings` carries them; `Outgoing.from: Option<String>` (must be one of the account's addresses, checked in the core, so neither a window nor an agent can put any address there); `compose::draft` takes all own addresses (reply from the one written to; Reply All leaves them out); the envelope sender follows; the refusal's words. "Own address" checks elsewhere (`senders.rs`, threads, the To column) use the set.
- C API: the addresses in the account calls; the From choices as a list from the core.
- Apps: Other addresses in Account Properties; the From list.
- Tests: unit tests for reply address choice and Reply All; `pe-smtp` conformance for From and envelope; `e2e_core` against ImapKit (sent from the alias, arrives with it; reply to mail sent to the alias goes from it; a server refusing the sender gives the explanation). UI tests: `account-12-other-addresses`, `write-25-from-alias`, `write-26-reply-from-alias`.

### PR 7: `feat(core): message rules` (M, no UI)

- `pe-store`: migration `rules (id, position, enabled, name, account_id NULL, query, move_to, mark_read, flag, archive, junk, delete, quiet, created)` and `messages.rule` (the rule that handled it). `query.rs`: `list:` and `Query::rule_problems()` (the terms a rule may not hold). `search.rs`: `Search` limited to given UIDs of a folder, so matching new mail is the search itself.
- `pe-core/src/rules.rs`: `apply(folder, uids)`: fetch texts first when an enabled rule needs them, match in order, collect the actions per message, run them through the existing move, archive, junk, delete, flag and mark-read operations (Gmail labels included), record the rule. Called by the main worker where new Inbox mail is found today (`worker.rs`, before `Event::NewMail`, whose message set it trims). `apply_now(rule)` for mail already there, in batches. Loop guard: a message is handled once (by `messages.rule`), so two rules or two computers can not pass it back and forth.
- `agents.rs`: no tool reaches rules; a test says so.
- Tests: query tests; store tests of UID-limited search; rule order and the "moved away ends it" rule; `e2e_core` against ImapKit: mail arrives over IDLE and is moved, flagged, marked read; body words matched after the text fetch; Gmail (`x-gm-ext-1` plugin) labels; apply-now over 5,000 messages in batches; a rule naming a folder since deleted is skipped and reported, not lost mail. Timing on the 489,000 message store: matching a batch of new mail against 50 rules under 20 ms.

### PR 8: `feat: Message Rules` (L)

- `commands.toml`: `message_rules` (Tools), `create_rule_from_message` (Message and the right-click menu). C API: the rule list handle, get, save, delete, move, the match count for a query, apply now.
- Apps: the Message Rules window and the rule editor (Windows `rules.cpp` in the look of Outlook Express's Message Rules; `Rules.swift`; `rules.rs`), "Create Rule…" on the search results bar, the status bar's "sorted by your rules", the rule's name in Message Properties.
- Help: a new topic `message-rules` in every language, linked from `find-messages` and `search-words`; F1 context for both windows.
- Tests: UI tests on all three: `rules-1-list`, `rules-2-editor` (the live count), `rules-3-from-search`, `rules-4-from-message`, `rules-5-applied` (a message delivered through ImapKit's API lands in the folder), `rules-6-bad-query` (a date term refused with the reason), reorder and turn off.

### PR 9: `feat(core): messages for a dark window` (M, no UI change)

- `pe-html`: `Appearance { Light, Auto }` passed to the document builders. With Auto: `color-scheme: light dark`, the chrome and cards in both schemes through `prefers-color-scheme` (so a change of the system's theme needs no reload), and `dark.rs`: the decision (own dark styles, no backgrounds, own design) and the lightening of dark text colors in inline styles and `<font color>`, by contrast against the dark background. `editor.rs` and `editor.js` styles for dark; `outgoing_html` tests that nothing dark leaks into sent mail. Print documents always Light.
- A corpus of fixtures (Gmail, Outlook, Apple Mail, Thunderbird written mail; newsletters; receipts; mail with its own dark mode; plain text) with the expected decision for each.
- Tests: the corpus; contrast unit tests; the CSP unchanged; `cargo test -p pe-html`. Windows passes Light, so nothing changes there.

### PR 10: `feat(mac, linux): messages in dark mode` (M)

- C API: the appearance parameter (Windows passes light, which keeps `check-shells.sh` satisfied with a real change in `app/`). Mac and Linux pass Auto unless the Options switch is off; web view backgrounds set before load; the switch in Options.
- Tests: UI tests run the reading steps once more in dark on the Mac and Linux: `dark-1-plain`, `dark-2-written`, `dark-3-newsletter` (stays light), `dark-4-cards`, `dark-5-compose`, `dark-6-switch-off`; the sent message of `dark-5` checked over ImapKit's API to carry no colors.

## How every PR is done

1. On master, `git pull`, then a branch (`feat/<name>`). Another session may be working in this checkout: start each PR in a git worktree of its own.
2. The core and its tests first: unit tests, migration tests, `e2e_core` against ImapKit for anything that talks IMAP or SMTP.
3. `core/commands.toml` or the C API; rebuild `pe-ffi` and commit the header and the generated command tables.
4. The three apps.
5. Translations: English, then drafts in German, Estonian, Spanish and French by `core/locales/GLOSSARY.md`, each marked `# review: new`; `pe-i18n` tests and the pseudo-language run.
6. Help in every language (translations marked for review), the keyboard table, `docs/shells.md`.
7. **UI end-to-end**: the step in `scripts/ui-e2e/SCENARIO.md`, in `scripts/ui-e2e.ps1`, `UITestSteps.swift` and `linux/src/e2e/`, the entry in `scripts/feature-map.mjs`. Run `scripts/win-ui-e2e.sh`, `scripts/mac-ui-e2e.sh` and `scripts/linux-ui-e2e.sh`, look at the screenshots, run `feature-map.mjs --check` for each platform.
8. **UX, UI and product review, until nothing is left to improve**: for every change a user can see, look at the screenshots of all three platforms (English and the pseudo-language; light and dark on the Mac and Linux) as a principal UX designer and a mail client product expert would: layout, alignment, spacing, wording, the order of controls, keyboard use, focus, empty and error states, what a new user expects, and how Outlook Express, Thunderbird, Apple Mail and Gmail do the same thing. Write down what could be better, fix it, take the screenshots again, review again. Repeat until a round finds nothing. Note the rounds and what changed in the PR description; fixes are `fix(ux)` commits. Windows checks that need the desktop and can not be run are logged in `build/windows-ux-pending.md` and done when the session is back; CI's Windows screenshots (`ui-e2e` artifact) cover the rest.
9. **/simplify** over the changed code, with the maintainability check.
10. **/security-review** of the branch; fix what it finds, then go on in the same turn.
11. `cargo fmt --all`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test --workspace`, prettier on changed Markdown and YAML, `scripts/check-shells.sh`.
12. Commits in this order: `feat(core)`, `feat(windows)`, `feat(mac)`, `feat(linux)`, `feat(i18n)`, `docs(help)`, `test(e2e)`, then `fix(ux)`, `refactor` and `fix` as the reviews need.
13. Push, open the PR, `gh run watch`. Fix real failures; rerun flaky jobs at most 3 times.
14. Merge with a merge commit once CI is green and the last review round found nothing, then start the next PR from the updated master.

PRs 7 and 9 touch only the core and can be built in worktrees alongside the PRs before them.

## Security notes, per feature

- **Recovery copies** hold unsent mail in the local store, next to the cached mail, with the same file permissions; they go when the window closes. Attachment paths are read again on restore and a file that is gone is reported, not guessed.
- **Undo Send**: the reopened message goes through `reopen` and the editor's sanitizer like any draft. Agents can not shorten or skip their own wait through the new setting.
- **The From address** is checked in the core against the account's own list at send time; the list is edited only in Account Properties, never by an agent or by anything in a message.
- **Rules** act on remote data with the user's authority, so: no action that sends or deletes for good; a query is parsed into bound SQL values as search does; folder targets are ids, checked to exist and to belong to an account the rule covers; one handling per message; agents have no way to rules; "apply now" asks with the count before it runs.
- **Dark mode** only rewrites color values the sanitizer has already parsed; no script, no new sources in the CSP; the decision never depends on fetching anything.
- **Text Size** closes zoom paths rather than opening any.

## At the end

- Every PR merged; the release-please PR collects them as 0.18.0 and is left for you to merge.
- `build/windows-ux-pending.md` empty, or its open items listed with the reason.
- `node scripts/i18n-review.mjs --html build/i18n-review.html` lists the draft translations to edit.
- The homepage screenshots refreshed with `scripts/homepage-screenshots.sh` (dark mode gives the Mac and Linux a second set), as a PR in `postalsys/inboxclassic.com`.
