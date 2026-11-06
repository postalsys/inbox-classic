# All Inboxes

The plan for an "All Inboxes" item in the folder tree: when there are two or more accounts, one item above them lists the mail of every account's Inbox in one list. The review it comes from measured the queries on a store of 489,000 messages (120,000 in three Inboxes): the first page takes 0.5 ms, the count 12.5 ms, finding a row's position about 40 ms.

## Decisions

- **Shown** only with two or more accounts, at the top of the tree, above the accounts. It goes when only one account is left; if it was selected, that account's Inbox is selected instead.
- **Sorted** like every folder: by the list's sort header, Date by default (the Date header, the received date when there is none); the Received header sorts by internal date.
- **At start** with two or more accounts the app opens on All Inboxes with the newest message of any Inbox selected; with one account, on its Inbox (as `start_message` does now).
- **Create Mail** while it is selected starts from the account of the selected message, or the first account when none is selected.
- **The Find box** searches every folder from All Inboxes as it does from a folder (the search ends the scope, Esc brings it back).
- **Only the Inbox.** All Sent and All Drafts can come later on the same scope.

## Core

1. `pe-store` `Search`: `folder: Option<FolderId>` becomes `scope: Scope`, with `Scope::Folder(FolderId)`, `Scope::AllInboxes` (`folder_id IN (SELECT id FROM folders WHERE path = 'INBOX' COLLATE NOCASE)`, the filter `Place::Inbox` already builds) and `Scope::Everywhere`. A typed `in:` still overrides the scope, as it overrides the folder today.
2. A migration: `messages_all_by_received ON messages (internal_date, uid, id)`, so the Received order of a list over several folders does not scan the table (14 ms to 0.6 ms for the first page). It helps the search of every folder too.
3. `Core::mark_all_inboxes_read`: `mark_all_seen` on each Inbox, a STORE per account in the background (Edit > Mark All Read and the item's menu).
4. `Core::start_message` returns a scope: All Inboxes and the newest message of every Inbox when there are two or more accounts, the first account's Inbox otherwise.
5. Tests: the store lists two accounts' Inboxes in date and received order without their other folders; `count_search` and `search_index` in the scope; `in:sent` typed overrides it; `start_message` with one and with two accounts; in `e2e_core`, mail arriving in the second account's Inbox is listed, and Mark All Read reaches both servers.

## C API

- `PeSearch` gets `all_inboxes: bool` (the folder 0 then means the scope, not every folder); `pe_start_message` gets a flag for All Inboxes; `pe_mark_all_inboxes_read`. The header is regenerated and committed.
- The unread count of the item is `pe_inbox_unread`, already exported for the tray.

## The three apps

The same in each, in its own tree:

- **Windows** (`app/src/mailbox.cpp`): an item inserted first in `Reload` with a reserved `LPARAM` (accounts are negative ids, folders positive), the `FOLDER_INBOX` icon, its unread count in the bold label as a folder's. A member `allInboxes_` that `Search()` turns into `all_inboxes`; `ShowFolderColumn` shows the Folder column for it as for a search.
- **Mac** (`Mailbox.swift`): a third node kind next to `AccountNode` and `FolderNode` at the top level of the outline.
- **Linux** (`folders.rs`, `mailbox.rs`): an `Entry` for it in the tree model; `search()` sets the scope.

In all three:

- Selecting it shows "All Inboxes" in the folder bar and the status bar counts of the scope.
- On `FolderChanged` of any Inbox: its count is updated, and the list reloads (the timer a search of every folder already uses).
- Commands that need one folder are off for it: New Folder, Rename, Delete Folder, Import, Empty, and dropping messages on it. Mark All Read uses the new call. Reply, Forward, Move, Delete and Junk act on the row's own folder, as in a search.
- Create Mail as decided above (`CurrentAccount`).
- `SelectStart` selects it when the core says so.

## UI tests, help and homepage

- A step after the second account is added (SCENARIO section 38): All Inboxes is at the top; it lists the mail of both accounts with the Folder column naming each; a reply goes from the account of the message; Mark All Read marks both Inboxes on the servers. After the account is removed (section 39): the item is gone. In `scripts/ui-e2e.ps1`, `mac/.../UITestSteps.swift`, `linux/src/e2e/steps.rs`, `SCENARIO.md` and `feature-map.mjs`.
- The help: the tree section and the start behavior.
- A homepage tour shot of All Inboxes with two accounts.

## Order of work

One pull request, in the repository's order: the core and its tests; the C API and header; the three apps; the UI test steps and feature map; the help; screenshots.
