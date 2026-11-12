# Account order and a new help

Two changes: the accounts get an order of their own, set by dragging their rows, and the help is rewritten into
topics and shown the way each platform shows help. Overview: `docs/reorder-and-help-overview.html`.

## Decisions

- **One account order.** Dragging an Inbox under All Inboxes, or an account's own row, reorders the accounts. The rows
  under All Inboxes and the account trees below follow the same order. Move Up and Move Down on the account's menu do
  the same from the keyboard.
- **Windows:** an in-app help viewer in the tri-pane look of classic Windows help: Contents and Search on the left, the
  topic on the right, Back, Forward, Home and Print. Not `.chm`: HTML Help runs the Internet Explorer engine, which the
  security model avoids.
- **Mac:** an Apple Help Book in the app bundle, opened in Help Viewer, its topics found by the Help menu's search. The
  help window goes.
- **Linux:** the topics installed for Yelp too; Yelp opens them when it is installed (GNOME, Ubuntu), the app's own
  libadwaita viewer otherwise (Omarchy and other Arch setups).
- **The website:** the same topics on inboxclassic.com/help, per language and platform, made at release time.
- **Pictures:** a few, from the UI tests' screenshots, per platform.
- **Languages:** all five ship the new help; the translations are marked for native review, as now.

## Part 0: an HTML message's title shown as its first line

`~/Downloads/payout.eml` (a Stripe payout notice) has `<title>Your €1,910.91 payout for EmailEngine is on the way</title>`
in its `<head>`, and the reading pane shows that sentence above the message. Other mail clients do not.

**Cause:** `mail_builder()` in `core/crates/pe-html/src/lib.rs` drops the `title` tag, which is not allowed, but ammonia
keeps the text inside a removed tag unless the tag is in `clean_content_tags`. That set holds only `script` and `style`
by default, and we take `style` out (`rm_clean_content_tags(["style"])`) because we keep style elements. So
`<html><head><title>TITLE TEXT</title><style>p{}</style></head><body><p>body</p></body></html>` comes out as
`TITLE TEXT<style>p{}</style><p>body</p>`.

**Fix (core only, no C API, command or UI change):**

1. `mail_builder()`: `.add_clean_content_tags(["title", "template", "noembed", "noframes"])`, whose content browsers do
   not show either. None is an allowed tag (ammonia panics if a tag is in both sets); `style` stays as it is.
2. `mail_builder()` also serves the editor and sending (`editor_document`, `outgoing_html`, and the plain-or-not
   comparison in `editor.rs`): check that dropping a title's text is right there too. It is: a title has no place in a
   body we send.
3. Tests in `pe-html`: a full document with `<title>` in `<head>` renders with no trace of the title's text, its body
   and style elements kept; the same for `template`, `noembed` and `noframes`.
4. `cargo test -p pe-html`, then in `core/` `cargo test --workspace`, `cargo clippy --workspace --all-targets` and
   `cargo fmt --all`.
5. Open `payout.eml` in the app (File > Open, or import) and check the pane starts with the message itself.

## Part 1: account order

### Core

- `pe-store`: a migration `ALTER TABLE accounts ADD COLUMN position INTEGER NOT NULL DEFAULT 0`, then
  `UPDATE accounts SET position = id`; a new account goes last. `accounts()` orders by `position, id`; `inboxes()`
  (All Inboxes' rows) by the account's position.
- `pe-core`: `Core::move_account(account, index)`: renumbers the positions in one transaction and sends
  `Event::AccountsChanged`, which the apps already answer by building the folder list again.
- C API: `pe_account_move(core, account, index)`; header committed.
- Tests: the order after moves, a new account last, All Inboxes' rows in the same order, the migration keeping today's
  order.

### Commands and words

- `core/commands.toml`: `account_move_up` and `account_move_down`, on the account's menu (the account row and its row
  under All Inboxes), greyed at the ends.
- Strings `ui-move-up` and `ui-move-down` in the five languages, marked for review.

### The apps

- **Windows** (`mailbox.cpp`, the folder TreeView): `TVN_BEGINDRAG` on an account row or an Inbox under All Inboxes
  starts a reorder; `TVM_SETINSERTMARK` draws the line between rows; the drop calls `pe_account_move`. Only between
  rows of that level; a message dragged onto a folder works as before.
- **Mac** (`Mailbox.swift`, the NSOutlineView): the rows write their account id to the pasteboard; `validateDrop`
  takes a drop between rows of the same level (the gap line AppKit draws); `acceptDrop` moves.
- **Linux** (`folders.rs`): a `gtk::DragSource` on those rows and a `DropTarget` that draws an insertion line above or
  below the row under the pointer.
- Each: the moved row stays selected, the list scrolls to it.

### Tests and docs

- `SCENARIO.md`: a step that drags the second account above the first and checks both lists, then Move Down puts it
  back. Each platform's UI test, a screenshot mid-drag where it can (`all-inboxes-4-reorder`).
- `feature-map.mjs`: the feature "Reorder accounts".
- The help topic "All Inboxes and several accounts".

## Part 2: the help

### What is wrong now (audit)

- One page of about 880 lines in nine parts; the contents list has no links. "Reading mail" is one bulleted list of
  about 140 lines covering reading, search, conversations, delete, move, junk, flags, archive, folders and undo.
- Internals in tasks: Thunderbird's ISPDB, Autodiscover, UIDPLUS, `$Junk`, DKIM and RFC 8058 inside the steps.
- **Wrong keys on the Mac:** the shared text writes Ctrl+Q for Mark as Read, which the Mac page turns into ⌘Q (Quit);
  Ctrl+F for Forward becomes ⌘F (Find); the copying drag says ⌘ where the Mac uses Option.
- Names that differ from the app's words ("Mark Read" for "Mark as Read", "Create Mail" against "New Message"),
  straight apostrophes in 38 lines while the app uses ’, "colour", "grey", "Bin".
- Features missing or buried: Check for Updates, the Linux main menu, the spell-check language, conversation keys,
  what the app connects to, the code notification option.
- Form: Tahoma at about 115 characters a line on every platform, no dark mode, no navigation, no search, F1 always opens
  the top of the page.

### One source, topics

- `core/crates/pe-html/help/<lang>/<topic>.html`: one file a topic, a restricted HTML subset (`h1`, `p`, `ol` for steps,
  `ul`, `table`, `aside.note`, `kbd`, `img`, `a href="topic:<id>"`), with the `<!--os:-->` parts as now.
- `core/crates/pe-html/help/topics.toml`: the ids in order, each with its section and the dialog it belongs to.
- **Keys from `commands.toml`:** `<kbd data-command="mark_read"></kbd>` becomes the platform's key (⌘⇧U on the Mac,
  Ctrl+Q elsewhere, Strg in German), written in each platform's way (⌘⇧N, not ⌘+⇧+N). No key is typed by hand, so they
  can not drift again.
- **Names from the catalogs:** `<b data-text="ui-mark-read"></b>` becomes the app's own word in the language, so the
  help always names a control as the app does.
- `pe-html`: `help_topics(platform, lang)`, `help_topic(id, platform, lang)` (a document with the platform's style:
  Tahoma on Windows, the system font and dark mode on the Mac and Linux), and `help_search(query)`, a word search over
  the topics' text. C API: `pe_help_topics`, `pe_help_topic`, `pe_help_search`.
- A check in `cargo test`: every `topic:` link and `data-command` and `data-text` resolves, every topic is in
  `topics.toml`, every language has every topic.

### The viewers

- **Windows:** `help.cpp`: a window with a toolbar (Hide, Back, Forward, Home, Print), a tab control with Contents (a
  TreeView of the sections and topics) and Search (a box and a results list), and the WebView2 with the topic. F1 in a
  dialog opens its topic.
- **Mac:** `scripts/mac-build.sh` writes `InboxClassic.help` (a bundle with `<lang>.lproj` folders) from
  `cargo run -p pe-html --example help-export -- mac`, indexes each language with `hiutil -Caf`, and sets
  `CFBundleHelpBookFolder` and `CFBundleHelpBookName` in Info.plist. Help (⌘?) and the dialogs' help buttons call
  `NSHelpManager.openHelpAnchor`. The Help menu's search then lists topics. The UI test checks the bundle and the index
  (Help Viewer itself can not be driven).
- **Linux:** the export writes Mallard pages too; the packages (deb and Arch) install them to
  `/usr/share/help/<lang>/inbox-classic/`. With `yelp` on the PATH, F1 opens `help:inbox-classic/<topic>`; without it,
  the app's viewer: an `AdwNavigationSplitView` with a search entry and the topics in the sidebar, the topic in the
  WebKitGTK view.
- **Context help** on all three: Add Mail Account, Account Properties, Options or Preferences, Sign-in Apps, AI Agents
  and the Address Book open their own topic.

### The website

- `scripts/release.sh` runs the export for the web and copies it to `../inboxclassic.com/help/<lang>/<platform>/`,
  with a platform switcher, the sitemap, `llms.txt` and a Help link in the homepage's header and footer.

### New structure

| Section              | Topics                                                                                                                                                                                                                                                                                     |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Get started          | Add your first account; Gmail and Outlook.com; The main window                                                                                                                                                                                                                             |
| Everyday tasks       | Read messages; Find messages; Conversations; Organize mail (move, copy, archive, flags, junk); Delete and undo; Folders; Write a message; Reply and forward; Attachments; Drafts, the Outbox and sending; Signatures; The Address Book; Save, print and import; New mail and notifications |
| Several accounts     | All Inboxes and several accounts (order, names); Manage accounts                                                                                                                                                                                                                           |
| Message features     | Sign-in codes; Delivery problems (bounces); Calendar invitations; Unsubscribe; Brand logos                                                                                                                                                                                                 |
| Settings             | Options and language; Account security settings; Default mail program; Updates                                                                                                                                                                                                             |
| AI agents            | Connect an agent; What an agent may do; Sending with an agent                                                                                                                                                                                                                              |
| Reference            | Keyboard shortcuts (made from commands.toml); Search words                                                                                                                                                                                                                                 |
| Troubleshooting      | Password not accepted; Certificate and TLS errors; Encryption errors; No connection; A message that cannot be shown                                                                                                                                                                        |
| Privacy and security | Pictures and tracking; Links and scripts; Where your mail and passwords are kept; What Inbox Classic connects to; Removing Inbox Classic                                                                                                                                                   |
| Advanced             | Your own sign-in app; Command-line options                                                                                                                                                                                                                                                 |

### Style guide

1. One task or one idea a topic, under about 300 words.
2. A task starts with "To ...", then numbered steps; each step one action, then what happens.
3. Sentences under 25 words, you, active, present tense.
4. Controls in bold, by their names from the catalogs (`data-text`).
5. Keys only through `data-command`.
6. Protocols and RFCs only in Privacy and security or Advanced, never in steps.
7. The app's typography: ’ and “ ”, "cannot", US spelling (color, gray), Trash on the Mac.
8. Warnings in a note before the step they warn about.
9. Tables for reference only.
10. Up to three related topics at the end.

### Pictures

From the UI tests, per platform: the main window with its parts named (`read-1-html`), Add Mail Account
(`account-1-form`), the agent's send question (`agents-4-send`), a bounce (`bounce-1-failed`), All Inboxes
(`all-inboxes-3-accounts`). English pictures for every language until the tests take them in each. Width-limited and
compressed; `scripts/help-pictures.sh` refreshes them.

### Translation

The English topics first; then German, Spanish, Estonian and French, each passage marked `<!--review-->` for
`scripts/i18n-review.mjs`.

### Review loop

Screenshots of every viewer in every language on every platform: the contents, a task, the shortcuts, a search and a
context-help topic. Reviewers as an MDN editor, a Windows, a Mac and a GNOME help expert and the four languages' readers;
fix and repeat until a pass comes back clean.

## Order of work

0. **The title fix** (one PR): small, first.
1. **Account order** (one PR): core, C API, commands, three apps, tests, help line. Small to medium.
2. **Help engine** (one PR): topics, `topics.toml`, keys and names from the sources, search, the export, the three
   viewers and context help, with today's text cut into topics. Large.
3. **Help content** (one PR): the rewrite in English with the style guide and pictures, then the four translations,
   the review loop. Large.
4. **Website help** (homepage repo and `release.sh`), after 3.

Before each commit: `/simplify` and `/security-review` on the change (and what they find fixed), prettier on Markdown and
YAML, `cargo fmt`, the tests. Then commit, push, open the pull request and watch CI until it passes.

## Risks

- Help Viewer on the Mac caches books and is slow to pick up a new one; the build bumps the book's version, and an
  ad hoc signed build may need `hiutil` and a restart to show it. Its look can not be styled much.
- Mallard is a second output to keep right; the export is the only writer, tested by validating the pages with
  `yelp-check` in the Linux container.
- Dragging in a classic TreeView has no built-in reorder; the insert mark and auto-scroll are hand-made.
