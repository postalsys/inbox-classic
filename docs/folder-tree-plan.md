# A folder list that starts with the Inbox

The folder list reads as a mail program's list does: the Inbox first, then Flagged, then the rest. With one account there is no account heading; with several, All Inboxes holds the only Inbox rows, one per account, and each account's heading holds the rest of its folders.

## Decisions taken

| Question                                     | Answer                                                                                                                 |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| One account: where the account's commands go | Tools menu only (Account Properties, Send and Receive, New Folder at the top). No account row, so no account menu.     |
| Several accounts: the Inbox rows             | Under All Inboxes only, each named after its account; All Inboxes open by default, can be collapsed, and that is kept. |
| Subfolders of an Inbox                       | Moved one level up: they sit at the account's top level, first among its folders (Inbox itself has no children).       |
| A server's own flagged folder (Starred)      | Stays as it is listed.                                                                                                 |
| Where the tree is built                      | In the core: one list of rows for all three apps, which only draw it.                                                  |

## The order

**One account**

1. Inbox
2. Flagged
3. Inbox's former subfolders, in their order
4. The other folders, in the server's order (Sent Items, Drafts, Archive, Junk E-mail, Deleted Items, the user's folders), nested as on the server

No account heading. Nothing to collapse at the top level.

**Several accounts**

1. All Inboxes, its children each account's Inbox named after the account (in the accounts' order)
2. Flagged
3. Each account, a heading (collapsible, its state kept), with its folders but the Inbox: Inbox's former subfolders first, then the others

## The core

- `pe-core/src/tree.rs`: `Core::folder_tree() -> Vec<TreeRow>`, the whole list in order. Each row: its kind (All Inboxes, an account's Inbox under it, Flagged, Inbox (one account), account heading, folder), the folder and account it stands for, depth, label, own unread and the unread hidden while collapsed, bold, whether it can be selected, collapsed, dragged (accounts and the rows under All Inboxes), dropped on, and which menu it has. One rule set, tested once.
- C API: `pe_folder_tree` (rows owned by the list, as `pe_folders` today); Linux calls the core directly. Counts refresh the same way the rows come, so the apps keep no tree logic of their own.
- The orders that follow the tree: Next Unread walks the tree's order (Inbox first); Move/Copy and Go to Folder (`targets.rs`) show no account row with one account; the rules' folder picker is unchanged.
- One account with no account row: New Folder with Inbox or Flagged selected makes a folder at the top level.
- Tests: one account, two accounts, an Inbox with subfolders (Dovecot's `INBOX.x`, Gmail's labels under none), an account whose server lists no Inbox yet, reordered accounts, collapsed headings.

## The three apps

Each draws the core's rows and drops its own building of them (`mailbox.cpp` `Reload`/`FillAccount`/`FillAllInboxes`, `Mailbox.swift` `reload`, `linux/src/mailbox.rs` `reload` and `folders.rs`), keeping its own look: the classic tree on Windows, the source list on the Mac (headings are group rows), GTK 4 on Linux. Selection, counts, menus, drag and drop, the open and closed state and the folder pane's drop-down use the rows' kinds instead of their positions. With one account, Tools gets the account's commands where they are not there already.

## Tests, help, review

- Core unit tests of the orders; the UI tests of the three platforms no longer find rows by position (Windows `FirstAccountItem`, the Flagged step that takes the first row, the Mac's `selectFolder(index)`); SCENARIO steps 19e, 27, 42, 42a, 42c, 43, 44 and the feature map (`main-1-inbox`, `main-10-flagged`, `all-inboxes-3-accounts`, `account-menu`, `folders-5-collapsed`) say the new order, with screenshots of one account and of two.
- Help, every language (translations marked for review): `main-window`, `all-inboxes`, `organize-mail`, `manage-accounts`, `folders`, `add-account`.
- UX review as a principal mail UI, design and product expert, from the screenshots of all three platforms (one account, two accounts, collapsed, dark mode, narrow window), fixing and looking again until nothing is left.
- /simplify, /security-review, the tests, then one pull request with the core and the three apps, merged when CI is green.

## When

After the OpenPGP pull request that is open at the time (the security bar) is merged, as its own pull request: the two touch different parts of the apps.
