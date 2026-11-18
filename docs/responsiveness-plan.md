# Instant feedback, then the data: the responsiveness plan

The review and its measurements are in `responsiveness-overview.html` beside this file (a synthetic store of 3 accounts and 232,000 messages). In short: every app runs the list queries on the window thread inside the click, so a folder row is highlighted only after its list has loaded (about 80 ms for All Inboxes grouped, several times that on a real disk), and the same pattern freezes the window when syncing, on grouped row clicks, in message windows, on Select All and Mark All Read. A grouped search with Expand All freezes for 6.7 s (a query plan bug).

## Decided

- **When**: all three steps back to back, right after #9 (attachments) and #1 (settings and accounts), before #2 (languages) and the remaining OpenPGP pull requests.
- **While a list loads**: the previous list stays, dimmed and not clickable, until the new one is drawn; "Loading..." only after 400 ms.
- **A big action the server refuses**: Mark All Read, Move and Delete act on the list at once; if the server refuses, the rows come back as they were and a bar over the list says why, as Delete's Undo looks.

## The principle

Within one frame the row clicked is highlighted, the folder bar and title say where you are and the focus moves; nothing that reads the store runs in the click. Within 100 ms the list shows the new folder. A newer request wins; one nobody waits for is dropped.

## Step 1: paint first

- The selection handlers only record the row and schedule the list load after the paint (Windows PostMessage, Mac after the run loop turn, Linux an idle callback); the old list dimmed meanwhile; startup shows the tree first.
- Core: the grouped count with a search materializes the conversations first (the 6.7 s bug); ungrouped row count is the count already made; a list's sort stops re-reading folder counts per page; a grouped row click uses the page in memory.
- Sync: changes to the folder shown gathered for 300 ms; a reload during sync refreshes counts and visible rows, keeping scroll and selection; the Address Book search waits 150 ms after the last key.

## Step 2: lists off the window thread

- `pe_list_view_load(view, generation)` answered by a `ListReady` event with counts, row count, the first page and the selected row's place, computed on a read connection of the core's own; later pages the same way, one ahead; newest wins (the message view pattern).
- The apps draw from the snapshot, never query in a paint; rows not yet here are blank lines of the right height; sort, grouping, Hide Read and Expand All use the same load.
- Also off the window thread: reading a message's source, Reply, Forward, drafts, attachments; Mark All Read, Move and Delete of many (optimistic, rolled back with a bar when refused); Select All's count at once, the messages only when a command needs them.

## Step 3: queries that do not grow

- Folder totals and unread kept in the folders table as messages change; All lists add their folders up.
- A conversation summary table per folder (newest date, count, unread, flagged), indexed by folder and date, for grouped pages.
- Keyset paging: pages, previous and next, and a message's place from its sort key with an index; indexes for sender and subject orders across folders. A migration (new entries in `schema.rs` `MIGRATIONS`).

## Checks

The review's benchmark becomes a timed core test in CI (a 230k-message store, each list operation against a budget); each platform's UI test measures click to highlight and click to list with a large store; a UX review of the waits (no empty flashes, no jumping rows, loading words only after 400 ms); /simplify and /security-review per pull request.
