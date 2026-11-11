# Each account's Inbox under All Inboxes, account names, the account's menu

The plan for showing every account's Inbox as a row under All Inboxes, as Apple Mail does: the rows are the same Inboxes the account sections have, a second way to reach them. Selecting All Inboxes lists the mail of every Inbox, as now; selecting one of the rows under it lists that Inbox alone. It builds on `docs/all-inboxes-plan.md`, which made All Inboxes.

Two more parts go with it, as they decide what those rows are called and what an account's row offers:

- **An account name**: a short name of the account's own ("Gmail", "Postal Support") that the folder list and the rows under All Inboxes show, in place of today's "Your Name (address)". Outlook Express had it as the first field of an account's Properties ("Mail Account"); Apple Mail calls it Description.
- **The account row's right-click menu** gets Send and Receive, Mark All Read and Properties... beside its New Folder.

## What it looks like

```
v  All Inboxes             12
      Gmail                 9
      Postal Support        3
      Zone
v  Gmail
      Inbox                 9
      Sent Items
      ...
v  Postal Support
      ...
```

- All Inboxes gets an expander; its rows are the accounts' Inboxes, in the order of the accounts below, each named by its account name (the name the account's heading has), with the Inbox icon and its own unread count.
- An Inbox row under All Inboxes has no subfolders, even when the Inbox has some: those are under the account.
- A row there and the account's Inbox row are the same folder: the same list, the same unread count, the same commands.

## What there is now

- The core has no row for All Inboxes; each app adds it (`kAllInboxesItem` on Windows, `AllInboxesNode` on the Mac, `ALL_INBOXES = i64::MIN` on Linux). The list's scope is `Scope::AllInboxes` or `Scope::Folder(id)` (`pe-store/src/search.rs`), so an account's Inbox selected from either place is already the existing folder scope: the list needs no change.
- Every app assumes a folder id appears once in its tree: `items_` on Windows (`app/src/mailbox.cpp`, folder id to one `HTREEITEM`), `folderNodes` on the Mac (`Mailbox.swift`), `items` and `parents` on Linux (`folders.rs`). Selection, a notification's message (`ShowMessage`), Next Unread, Go to Folder, dropping messages on a folder and Rename and Delete Folder all go through that one row.
- Which folders are Inboxes is decided twice: the store by path (`path = 'INBOX'`, `search.rs`), the Windows and Mac apps by special use. Not the same rule.
- Nothing remembers which rows are open; accounts open at every start.

## Decisions (proposed)

1. **A row has a place, not only a folder.** Each tree row is identified by `(folder, under_all_inboxes)` in all three apps. The maps keyed by folder id keep the account's row; the rows under All Inboxes get a map of their own. Every place that selects a folder by id selects the account's row, except as in 2.
2. **Which row a folder's selection goes to.** When the folder is selected from outside the tree (a notification's message, Next Unread, the message window going to the next message, the start), the row under All Inboxes is selected when the selection was already under All Inboxes (on it or on one of its rows); the account's row otherwise. So someone working from All Inboxes stays there.
3. **Unread counts.** Each row under All Inboxes shows its Inbox's count. All Inboxes shows the sum only while it is closed, the same rule the tree already has for a folder with closed subfolders (a parent's own count when open, with the hidden ones' added when closed).
4. **Commands.** A row under All Inboxes is the Inbox: Mark All Read, Properties, dropping messages on it (moves them to that account's Inbox), the context menu of an Inbox. New Folder from it makes the folder under that account's Inbox. Rename and Delete stay off, as for any Inbox.
5. **Shown with two or more accounts only**, as All Inboxes is now. With one account there is nothing to gather.
6. **The core decides which folders are Inboxes**, one rule for all, in a call general enough for All Sent and All Drafts later: `pe_special_folders(core, use)` returning one row per account (account id, folder id, the account's name, unread) for a special use (Inbox now), in account order, from the store's rule. The apps build the rows under All Inboxes from it and drop their own special-use checks for this.
7. **The folder bar and the title** read "Inbox - Gmail" for a row under All Inboxes, so the two Inboxes are told apart; the account's own row keeps "Inbox".
8. **Open rows are remembered** between starts: All Inboxes and each account (by its id), open or closed, in each app's own preferences (Windows' settings, the Mac's defaults, Linux's settings.ini), as plain app preferences are. A new account starts open; a removed one's entry is dropped. Today every account opens at every start.

## Improvements beyond the request

- **One Inbox rule** (decision 6) fixes a quiet difference: an account whose server names its Inbox differently could be in the store's All Inboxes but not marked as an Inbox in the Windows and Mac trees, or the other way round.
- **Later, on the same rows**: All Sent and All Drafts (Apple's next rows) are the same pattern with another special use, through the same `pe_special_folders`; a Flagged row is a search (`is:flagged`) over every folder. Not in this change.
- **The narrow window** (the Linux folder button's popover, new in the Omarchy work) shows the same tree, so the rows work there too; the button names "Inbox - Gmail" as the title does.
- **Accessibility**: a row under All Inboxes is named "Inbox, Gmail" for screen readers, not only "Gmail".

## Account names

- **The field**: "Account name" in an account's Properties, the first field, above "Your name" (the name on mail sent, as now). The help says what each is for.
- **What shows it**: the account's heading in the folder list, its row under All Inboxes, the Account column of All Inboxes' list, the folder bar and title ("Inbox - Gmail"), File > Accounts, Go to Folder and Move to Folder's lists. Not the From of a new message, which shows the sender as the recipients will see it ("Your Name <address>").
- **When two accounts have the same name**, the address is added to both, as for display names now, so they can be told apart.
- **New accounts** get a name from their provider: Gmail, Outlook.com, iCloud, Yahoo and the like by the address's domain (the table `pe-autoconfig` has for app passwords grows into it), the address's domain otherwise ("postalsys.com"). A Google or Microsoft sign-in on a company domain gets the domain. Add Mail Account's second step shows the field, filled, to change before Finish.
- **Existing accounts** keep what they show now until their name is set: an empty name means today's label (the display name, with the address when two are the same).

## The account's right-click menu

```
Send and Receive
Mark All Read
----------------
New Folder...
----------------
Properties...
```

- **Send and Receive**: this account only (`Core::sync(account)`, as the account's part of Send and Receive All).
- **Mark All Read**: every folder of the account, a STORE per folder on the account's worker; off when nothing in the account is unread.
- **Properties...**: the account's Properties, the dialog File > Accounts opens, named the same.
- New Folder stays as it is. Remove Account stays in File > Accounts only, where its confirmation is.

## Core

1. `Core::special_folders(use)` (and the store query under it): one entry per account, its folder of that special use (Inbox now), the account's name, the unread count, in the accounts' order. For the Inbox the rule is the store's (path `INBOX`), the one All Inboxes' list already uses; Sent and Drafts later by their special use.
2. The account name: a migration `ALTER TABLE accounts ADD COLUMN account_name TEXT NOT NULL DEFAULT ''` (a new entry in `schema.rs` `MIGRATIONS`), `AccountSettings.account_name`, `text.rs` `account_title` using it first and the display name's rule when it is empty, and `default_account_name(email)` for new accounts (the provider table, else the domain), with tests for each provider, a company domain, two accounts of the same name.
3. `Core::mark_account_read(account)`: `mark_all_seen` on each of the account's folders that has unread mail, in the background.
4. `pe_special_folders(core, use)` in `pe-ffi` returning an opaque list of `repr(C)` rows (`PeSpecialFolder { account, folder, name, unread }`), freed with its own call, as `pe_folders` does; `use` a `PeSpecialUse` enum (Inbox now); the header regenerated and committed.
5. The C API's account settings get `account_name`; `pe_default_account_name(email)` for Add Mail Account's second step; `pe_mark_account_read(account)`. The header is regenerated and committed.
6. `FolderChanged` is enough for the apps to refresh a row's count; an account renamed sends `AccountsChanged`, which already rebuilds the tree.
7. Tests: `special_folders(Inbox)` lists two accounts' Inboxes in order with their counts, not other folders; an account without an Inbox yet is left out.

## The three apps

- **Windows** (`app/src/mailbox.cpp`): All Inboxes becomes an item with children (from `pe_special_folders`), opened or closed as last time; the children's `LPARAM` carries the folder id with a high bit marking the place (folders are positive, accounts negative, `kAllInboxesItem` is `LPARAM` min), decoded in `TVN_SELCHANGEDW`. A map `inboxItems_` (folder id to the row under All Inboxes) beside `items_`. `ShowMessage`, Next Unread and `GoToFolder` choose the row as in decision 2. `ShowRow`'s closed-parent sum applies to All Inboxes.
- **Mac** (`Mailbox.swift`): an `InboxAliasNode(folder, account)` as the children of `AllInboxesNode`, the outline's open rows as last time, its own map beside `folderNodes`; `outlineViewSelectionDidChange`, `showMessage`, `goToFolder` and the drop validation handle it.
- **Linux** (`folders.rs`, `mailbox.rs`): `FolderItem` gets the place (`under_all_inboxes: bool`); the tree's open rows kept in settings.ini; `items` and `parents` are keyed by `(id, place)`; `select(id)` takes the place; `on_tree_selected` passes it; the folder button and the title name the account.
- **In all three**: the Account name field in Properties and in Add Mail Account's second step (`accounts.cpp`, `Accounts.swift`, `accounts.rs`); the account row's menu with the four items (Windows' tree context menu in `mailbox.cpp`, the Mac's outline menu in `Mailbox.swift`, `account_menu` in Linux's `mailbox.rs`).

## UI tests, help and feature map

- After the second account is added (SCENARIO section 44, "All Inboxes goes with the second account"): All Inboxes has a row per account, named by the account; selecting the second account's row lists only its mail (the first account's message is not in the list); selecting All Inboxes lists both; a notification's message opened while a row under All Inboxes is selected keeps the selection there. In `scripts/ui-e2e.ps1`, `mac/.../UITestSteps.swift`, `linux/src/e2e/steps.rs`, `SCENARIO.md`, and a feature `All Inboxes' accounts` in `scripts/feature-map.mjs`.
- An account's name: set in Properties, the tree's heading and its row under All Inboxes show it; a new account's second step offers its provider's name. The account row's menu: Send and Receive of one account reaches only its server; Mark All Read marks the account's folders and no other account's; Properties opens that account's dialog. Feature map entries `Account name` and `The account's menu`.
- Open rows: All Inboxes closed and the app started again, it is still closed, and an account opened stays open.
- The help's folder tree section: the rows under All Inboxes, the account's menu; the account Properties section: Account name and Your name.
- A homepage tour shot with two accounts and All Inboxes open.

## Order of work

One pull request, in the repository's order: the core (`special_folders` and `pe_special_folders`, the account name, `mark_account_read`) with tests; the three apps; the UI test steps and the feature map; the help; screenshots.

## Settled with you

- The account name is called **Account name**, the first field of Properties.
- **New accounts** get their provider's name (Gmail, Outlook.com, iCloud, Yahoo, else the domain); **existing ones** keep today's label until their name is set.
- The account row's menu says **Properties...**, as File > Accounts does, and gets **Send and Receive** and **Mark All Read**; Remove Account stays in File > Accounts.
- The rows under All Inboxes are named by the **account name alone** ("Gmail"), as Apple does; screen readers hear "Inbox, Gmail".
- A selection made from outside the tree **stays under All Inboxes** when it was there (decision 2).
- **Open rows are remembered** between starts, in this change (decision 8).
- The core call is the **general `pe_special_folders`**, so All Sent and All Drafts can follow on it; they are not in this change.
