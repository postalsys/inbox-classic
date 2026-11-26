# The deep test's journeys

What `pe-deep` does in the big world (`docs/deep-test-plan.md`), on every target: the core without a window, and the three apps. A journey is a fixed sequence with its own checks; after every step the conductor also runs the checks that always hold (row counts, rows in sight, the selection and the reading pane, the tree's counts, all against the server). The random walk comes after the journeys and is not written out here.

The regular scenario is `SCENARIO.md`. A bug found here gets a small step there.

The accounts: Work (20,000), Home (6,000, 400 folders), Gmail-like (5,000, OAuth), Lists (3,000, every kind of message), Broken (200, an ill server).

## Settled, and what holds before

A check runs either settled, after the driver waited for things to be quiet, or now and then before that (the walk's checks while things are under way, and those between Fast fingers' acts). Settled means, the same on every target:

1. the core is quiet (no sync, no action, no barrier: `pe_quiet`), the window is not reading its list and has no read mark to come (the message shown is marked read a moment after it shows, and a conversation shown marks its unread messages in other folders too);
2. a sync of every account as a barrier, which ends after every command queued before it, then 1 again;
3. the rows the window draws are the list as the store has it now. The window hands the core its row count and the message at each row in sight (blank where its page is not read), and the core answers (`ListView::drawn_current`, `pe_list_view_drawn_current`). This is the only test of the window's own state. Whatever is still on its way to it (an event in its queue, a reload gathering changes, a page, a paint) leaves the rows other than the core reads them, so no driver lists those things itself. The driver waits at most 10 seconds for it and does not fail. A row left blank, or a list left behind, is then the checks' to report.

A driver reads what is drawn and never fills it: looking at a row does not ask for its page.

While a list is read again (another folder chosen, a search, an order, conversations grouped), the windows show the rows they had until the new ones come: by design, as nothing waits on the window thread. So a check before settled asks only that the window answers and says what it shows; what its rows are is a settled check. While a folder chosen is read, the windows keep the list before drawn and dimmed, and the observation says so (`pending`).

| Check                                                                  | Before settled                  | Settled                                           |
| ---------------------------------------------------------------------- | ------------------------------- | ------------------------------------------------- |
| `pending`: the list before still drawn                                 | allowed, and no row check runs  | a failure                                         |
| `scope`, `twice`, `order`: rows of this list, each once, in date order | no (the rows before may show)   | yes                                               |
| `rows`: the list's row count against the server                        | no                              | yes                                               |
| `blank`: a row in sight without its message                            | no (its page may be on its way) | yes                                               |
| `ghost`, `flagged`: rows the server has, flagged ones in Flagged       | no                              | yes                                               |
| `pane`: the one row selected is the message shown                      | no                              | yes                                               |
| `tree`: each folder's unread count                                     | no                              | yes, except folders read in the last three opened |

## D1. The first sync

- the five accounts are added and synced as the target starts; each Inbox opened: every folder of every account has the server's total and unread count, each Inbox lists all its messages

Not built yet: the window used while the first sync runs, the counts only going up, the app quit in the middle of it.

## D2. Pages

- Work's Inbox, come to for the first time: a message is selected and it is its newest
- a row a fifth of the way down selected, to Flagged and back: the same row is selected, in sight, filled and shown (the incident, and the message left there)
- its message deleted by another client meanwhile: back in the Inbox the newest is selected
- End: the last rows are in sight and filled, the last row opens; Home and Page Down 40 times, then a row in sight opens
- scrolled to the middle: the rows in sight are filled and are the server's
- folders of exactly 100, 800 and 801 messages, and an empty one, each from the big Inbox and back: a message selected unless it is empty
- every sort column, both directions, scrolled to row 1,000: the rows in sight are the server's, in the order of their dates when sorted by date
- Unread Only on and off; conversations on and off

Not built yet: the column layout and dark mode switched in the big list.

## D3. Fast fingers

- ten of Home's folders clicked without waiting, then Work's Inbox: only its rows are shown, and they are filled
- none of the ten opened a message: their newest messages are still unread on the server
- the sort changed three times without waiting
- a search typed a letter at a time, then cleared at once: the folder's list is back
- a row clicked, then Flagged, then back before anything came

## D4. The list changes under the window

- scrolled to the middle, 200 new messages arrive: the count grows by 200
- at the top with a message shown, new mail arrives: the same message stays shown
- another client deletes the message shown: it is no longer shown
- scrolled to the end, another client deletes a sixth of the oldest: the list ends where the server's does
- another client flags the rows in sight
- the folder shown is renamed by another client: the list follows; another folder's UIDVALIDITY changes while it is shown

## D5. Selection across pages

- Select All in the big Inbox, Mark as Read: the server has none unread; Select All, Mark as Unread
- a Shift range from row 50 to row 2,300 without scrolling between, moved to Archive: Archive has exactly those more; Undo brings them back

Not built yet: a move the server refuses half way; Select All, a sync, then Delete.

## D6. Views of many folders

- All Inboxes, All Sent, All Drafts and Flagged, each to its end: the rows the servers have (Flagged: each row flagged on its server)
- All Inboxes remembers its own message apart from Work's Inbox

Not built yet: an account removed while its rows are in sight; the accounts' order changed. Broken's server ill is in D13 and the walk.

## D7. Conversations

- Work's Inbox by conversations: rows 99, 100 and 0 clicked, End; conversations off again

Not built yet: a conversation of 300 expanded; one across three folders; Watch and Ignore on a long one.

## D8. Finding

- a common word in Work's Inbox finds many: End, the last hit opens; `subject:` alone; a search in All Inboxes

Not built yet: every operator of the query syntax against the same question asked of the server; a hit deleted from the results.

## D9. Bulk commands

- Mark All Read on the big Inbox: the window stays usable meanwhile (scrolled while it runs), the server agrees at the end
- a folder of 800 deleted with Select All, then Empty Folder on Deleted Items: it is empty

Not built yet: a message rule run on a folder of 5,000 while its list is shown; an agent's bulk move with the window on that folder and its Undo; 500 messages dragged to a folder, saved as files and imported again. The regular scenario has each of them on a small folder (19g, 28, 30, 32).

## D10. Writing

- five messages sent in a row from Work, without waiting between them: Sent has each once; All Sent lists them

Not built yet: a reply into a long conversation, Undo Send among them, drafts while All Drafts is shown, actions queued off line.

## D11. The folder tree

- twelve of Home's folders three levels deep and more, in other scripts too, opened one after another; every count matches the server's

Not built yet: folders created, renamed, moved and deleted deep in the tree.

## D12. Every kind of message

- in Lists, found among 3,000 and opened from their rows: a bounce, an invitation, a one-time code, encrypted mail, a newsletter, a huge message (2, 8 or 40 MB by profile)

## D13. The connection

- the connection dropped at the next MOVE of a move of 220: each message is in Archive once at the end
- two slow FETCH commands on Lists: Work's mail is read meanwhile
- a server that refuses the next three connections (Home): the list and the counts still come right
- Broken's password changed elsewhere and set back: the other accounts work meanwhile (the core's run; an app asks for the new password in a window of its own, which the drivers do not answer)

The walk adds faults to Broken now and then: a dropped connection, a slow command, a refused connection.

## D14. Restarts

- Archive and the Inbox each left with a message shown, the app closed and started again: the same list and message, and Archive still opens with its own (the core's run; the drivers start their app once)

Not built yet: the sort and the place in the list after a restart, an encrypted newest message come to (no passphrase asked), a restart with a message window and a compose window open, the store closed hard in the middle of a sync.
