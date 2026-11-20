# The deep test's journeys

What `pe-deep` does in the big world (`docs/deep-test-plan.md`), on every target: the core without a window, and the three apps. A journey is a fixed sequence with its own checks; after every step the conductor also runs the checks that always hold (row counts, rows in sight, the selection and the reading pane, the tree's counts, all against the server). The random walk comes after the journeys and is not written out here.

The regular scenario is `SCENARIO.md`. A bug found here gets a small step there.

The accounts: Work (20,000), Home (6,000, 400 folders), Gmail-like (5,000, OAuth), Lists (3,000, every kind of message), Broken (200, an ill server).

## D1. The first sync

- the five accounts are added one after another; the window is usable from the first
- Work's Inbox lists its newest messages while the rest still arrive, and a message opens
- every folder's count only goes up until it is the server's
- the app is quit in the middle and started again: the sync goes on, nothing is listed twice
- at the end every folder of every account has the server's total and unread count

## D2. Pages

- Work's Inbox (18,000): the first rows are filled
- to Flagged and back: the first rows are filled and the top row opens its message (the incident)
- End: the last rows are filled, the last row opens; Home: the first again
- Page Down held for 40 pages, then a row in sight opens
- the scroll bar dragged to the middle: the rows in sight are the server's rows of that place
- folders of exactly 100, 800 and 801 messages, and an empty one, each from the big Inbox and back
- every sort column, both directions: the rows in sight follow the server's order
- Unread Only on and off; the column layout on and off; dark mode on and off: the same rows, the same selection

## D3. Fast fingers

- ten folders clicked without waiting, then one: only its rows are ever shown, and they are filled
- the sort changed three times without waiting
- a search typed a letter at a time, then cleared at once: the folder's list is back, whole
- a row clicked, then another folder, then back before the first message has come: the reading pane shows what is selected or nothing

## D4. The list changes under the window

- scrolled to the middle, 200 new messages arrive: the rows in sight stay, the count grows
- at the top, new mail arrives: it is listed, the selection stays on its message
- another client deletes the selected message: the selection moves as Delete would move it, the pane follows
- another client deletes 3,000 while the list is scrolled to its end: the list ends where the server's does
- another client flags, reads and moves messages in sight: the rows follow
- the folder shown is renamed, then deleted, by another client
- the folder's UIDVALIDITY changes: its list is read again, whole

## D5. Selection across pages

- Select All in a folder of 5,000: the reading pane says how many, and how many are unread
- Mark as Read, Flag, then Move to another folder: the server has all of them there, each once; Undo brings them back
- a Shift range from row 50 to row 2,300 without scrolling between: Delete removes exactly those
- a move the server refuses half way: the bar over the list says so, the rows are back and selected
- Select All, a sync, then Delete: what was selected is deleted, not what arrived

## D6. Views of many folders

- All Inboxes has the sum of the Inboxes, in the order of the dates; "by account" groups them
- All Sent, All Drafts and Flagged likewise
- Broken's server stops: its rows stay, its state is said, the other accounts' rows work
- Broken's password changes: the same, and it asks once
- an account is removed while its rows are in sight in All Inboxes: they go, the selection lands on a row that is there
- the accounts' order changed: the tree and "by account" follow
- from a row of All Inboxes to its own folder and back: the same row selected

## D7. Conversations

- Work's Inbox by conversations: as many rows as the server's messages make conversations
- a conversation of 300 expanded and collapsed; one at row 99 and 100 expanded
- a conversation with messages in three folders
- Watch and Ignore on a long conversation, then new mail in it
- conversations off and on in the big Inbox: the selected message stays selected

## D8. Finding

- a word with thousands of hits: the count is the server's, End reaches the last hit, it opens
- every operator of the query syntax in Work, against the same question asked of the server's messages
- a search in All Inboxes; a search while a first sync still fetches the text
- a hit deleted from the results: it leaves the results and its folder

## D9. Bulk commands, rules and agents

- Empty Folder on 10,000; Mark All Read on 18,000: the window stays usable meanwhile, the server agrees at the end
- a message rule run on a folder of 5,000 while its list is shown
- an agent moves 2,000 messages of the folder shown: the list follows; Undo from the agent's log
- 500 messages dragged to a folder; saved as files; imported again

## D10. Writing, in the big world

- a reply to a message of a long conversation lands in it
- 50 messages sent in a row, some with Undo Send: Sent has each once
- drafts saved, opened and deleted while All Drafts is shown
- off line: 20 actions queued, then on line: the server has them in order

## D11. The folder tree

- Home's 400 folders: the tree scrolls, expands and collapses; every count matches
- folders created, renamed, moved and deleted, here and by another client, deep in the tree
- names in other scripts sort and show as the core says

## D12. Every kind of message

- in Lists, each kind opened from a big list by its row: a bounce, an invitation, a one-time code, signed and encrypted mail, a brand logo, pictures and PDF previews, a message of 40 MB (its text first)
- encrypted messages in search results and in All Inboxes show no text they should not

## D13. The connection

- the connection dropped in the middle of a move of 3,000: the server has each message once at the end
- one slow command: reading other mail does not wait for it
- a server that refuses the extra connections: everything above still works
- an hour of IDLE with mail arriving now and then (the overnight profile: a night)

## D14. Restarts

- the folder, the sort, the selected message and the place in the list are the same after a restart
- a restart with a message window and a compose window open
- the store closed hard in the middle of a sync opens again and ends with the server's counts
