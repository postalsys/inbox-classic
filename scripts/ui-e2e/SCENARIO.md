# The UI end-to-end scenario

One scenario for the three apps, in this order. Each platform's test drives the real app through it against ImapKit (`core/e2e`) and checks the results on the server over its REST API, saving each screenshot under the name below, so `scripts/feature-map.mjs` (with `--check <platform>`) maps every feature to its picture on each platform:

- Windows: `scripts/ui-e2e.ps1` (UI Automation and window messages, `scripts/win-ui-e2e.sh`)
- Mac: `mac/Sources/InboxClassic/UITest.swift` and `UITestSteps.swift` (in the app's process, `scripts/mac-ui-e2e.sh`)
- Linux: `linux/src/e2e.rs` and `linux/src/e2e/` (in the app's process with the `e2e` feature, `scripts/linux-ui-e2e.sh`)

A new feature adds its step here and to all three tests, and its entry to `scripts/feature-map.mjs`. A screenshot a platform does not take yet is in `notYet` there (marked below), which makes the gap visible until it is closed.

## 1. Starting ImapKit

## 2. Starting Inbox Classic with a store of its own

Screenshots: `account-1-form`, `account-2-lookup`, `account-3-servers`, `account-4-warning`

- the account form opens
- it starts with the Google and Microsoft sign-in buttons
- and asks no password before the servers are known
- the server settings form follows the lookup
- the lookup guessed the IMAP server
- the server form keeps the name typed first
- a connection without encryption is warned about
- the window that waits while the lookup runs is shown on a lookup that never ends (the real one is over too soon for a picture, `account-2-lookup`), and Cancel ends it (Linux; the others shoot the real one when it lasts)

## 3. Syncing

Screenshots: `main-1-inbox`

- the folders of the account are in the tree
- the messages are in the list

## 4. Reading an HTML message

Screenshots: `read-1-html`

- showing the message marked it read on the server
- the paper clip of the attachments is there
- the information bar says pictures are blocked
- the title names the folder, as the folder bar does

## 5. Message properties

Screenshots: `read-7-properties`

- File > Properties opens the headers of the message
- the headers, without the body
- OK closes it

## 6. The message list menu and the message source

Screenshots: `read-14-menu` (not on the Mac: its menus run in a tracking loop of their own), `read-15-source`

- the message list has a right-click menu with the message's actions
- a read message offers Mark as Unread, not Mark as Read
- View Source opens the whole message
- with its header and every part, as the server has it
- the window names the message
- Save As in it asks where, with the subject as the name, and saves the message as it came
- and the source stays open
- Close closes it

## 7. Pictures from the internet

Screenshots: `read-2-pictures`

- clicking the bar shows the pictures, and the bar goes away

## 8. Saving the attachment

Screenshots: `read-3-attachments` (not yet on the Mac), `read-4-save` (not yet on the Mac, not yet on Linux), `read-4-save-failed`

- the paper clip offers the files to save
- choosing one asks where to save it
- the attachment is saved as it was sent
- and marked as from the internet

## 9. Marking unread and read

Screenshots: `read-5-unread`

- Mark Unread clears \Seen on the server
- Mark Read sets it again

## 10. A reply with the earlier message folded

Screenshots: `read-6-folded`

## 11. Forwarding

Screenshots: `write-1-forward`

- Forward opens a compose window
- the subject is marked Fw:
- the recipients are left to the user

## 12. Replying to all

Screenshots: `write-2-reply-all`

- Reply All opens a compose window
- it goes to the sender and the others
- but not to the account itself
- with the Cc kept
- the Cc row is open, as it has someone in it

## 13. Replying

Screenshots: `write-3-reply`, `write-3b-select-all` (not yet on the Mac, not yet on Linux)

- Reply opens a compose window
- the reply goes to the sender
- B shows bold is on
- the editor takes typing
- the reply arrived over SMTP
- the reply refers to the message it answers
- the reply has what was typed
- it is HTML with a text part
- what was typed in bold is bold
- the folded quote is sent along
- the quote is sent once
- a copy of the reply is in Sent

## 14. A new message

Screenshots: `write-0-new-empty`, `write-4-bad-address`, `write-5-new`

- Create Mail opens an empty compose window
- a new message shows no empty Cc, Bcc or Attach row
- the Cc and Bcc buttons are at the end of the To row
- Cc opens its row, and its button goes
- From names the account it goes from
- the editor of a new message takes typing
- a mistyped address is pointed out before sending
- and the message stays open to fix it
- Attach adds the files to the Attach row
- Delete in the Attach row takes one off
- the new message was sent
- with what was typed
- with only the file left attached
- nothing formatted: it went as plain text

## 15. Pictures dropped into the text

Screenshots: `write-13-dropped-picture` (not yet on the Mac, not yet on Linux)

- the editor takes typing
- a file that is no picture is attached
- the message with the dropped picture was sent
- the picture went inline, as a cid: part, like Insert Picture puts one
- with no data: URI left in the HTML
- the other file went as an attachment, the picture not

## 16. Links in a message being written

Screenshots: `write-14-link-status` (not yet on the Mac, not yet on Linux), `write-15-edit-link` (not yet on the Mac, not yet on Linux), `write-16b-unlinked`

- the Link button asks for an address
- with the cursor in a link, the status bar shows its address
- the Link button on a link shows its address to change
- and changes it
- the dialog shows the changed address
- an empty address removes the link
- the link text went, without the link

## 17. A message that is not downloaded yet

Screenshots: `read-13-downloading`, `read-12-not-downloaded`

- the header shows the message's sender and subject at once, from the list
- the pane says the message is being downloaded
- a message that can not be downloaded says why, with Try Again
- once the account is back the message shows by itself
- and Try Again goes

## 18. The Outbox: a send that can not go

Screenshots: `write-7-outbox`

- there is no Send Later: Send sends
- Send closes the message
- a send that can not go says it waits in the Outbox
- and it was not sent
- Tools > Outbox lists what waits
- the message is in it
- once the server is back it goes by itself

## 19. Drafts

Screenshots: `write-0-main-in-front` (not yet on the Mac, not yet on Linux), `write-8-save-draft`, `write-9-draft-reopened`, `write-10-draft-saved`, `write-11-sent`

- the message window is a window of its own
- the main window comes in front of a message being written
- closing a written message asks to save it
- Yes saves it and closes the window
- the draft is in Drafts on the server
- marked as a draft
- Drafts lists it
- opening the draft opens a compose window
- with its subject
- and its recipient
- Save replaces the draft
- the message window says when the draft is saved
- the finished draft is sent
- with all that was written
- and its draft is gone
- the main window says what was sent

## 20. Send/Recv

Screenshots: `main-2-new-mail`, `main-3-sent-items`

- the new mail is in the list
- Sent Items has what was sent
- Sent Items names whom each message went to, in a To column

## 21. Finding

Screenshots: `find-1-results`, `find-3-no-results`, `find-2-every-folder`

- there is a Find box, in a search field
- a click at $
- a folder has no Folder column
- typing in it narrows the list to what has it (the subject)
- it searches every folder: the list has a Folder column
- the search bar says what was found for what
- the folder bar says where
- and so does the title
- the sender address is found too
- and nothing when nothing has it
- the search bar says there are no results
- clearing it shows the folder again, without the Folder column
- and without the search bar
- an empty Find box has no clear button
- with text in it, it has
- which empties it and shows the folder
- words of the text are found
- Gmail operators work: from:
- in:inbox: the folder bar and the search bar say the Inbox
- the messages of other folders are found too
- is:unread lists the unread messages
- a result is shown in the reading pane
- Clear search on the search bar ends the search
- Esc ends the search: the folder again, without the Folder column

## 22. Saving and importing a message as a file

- Save As asks where, with the subject as the name
- and saves the message as it came
- Import Messages asks for files
- and puts the message in the folder, on the server

## 23. Flagging, deleting and moving

Screenshots: `organize-1-flagged`, `organize-2-move`, `organize-3-after`, `organize-4-for-good`

- a plain text message does not offer Download pictures
- Flag Message flags it on the server
- Delete puts it in Deleted Items
- and takes it out of the Inbox
- the list has one less
- Move to Folder asks where
- the selected message is in Archive
- and out of the list
- deleting for good asks first
- and then it is gone from the server

## 24. Unsubscribing

Screenshots: `read-8-unsubscribe`, `read-9-unsubscribe-ask`

- a message of a mailing list has Unsubscribe in its header
- it asks first, naming where it goes
- and the status bar says it is done

## 25. A calendar invitation

Screenshots: `read-10-invitation`

- a message with an invitation shows the event in a card above the text (the frame of the bounce and code cards): its
  title, when, where, the organizer, and Open in Calendar

## 26. A brand logo (BIMI)

Screenshots: `read-11-logo`

- a sender whose logo the server passed has it beside the header

## 27. A collapsed account

Screenshots: `folders-5-collapsed`

- the Inbox has unread messages
- the Mac and Linux: the account is a heading over its folders, which can not be selected (the arrow keys pass it by);
  a click on it closes it, the Inbox it hides stays listed with nothing selected in the tree, and a second click opens
  it again with the Inbox selected. Windows keeps Outlook Express's tree, where the account is an item that can be
  selected
- collapsed, the account shows the unread messages of its folders (Windows: in bold)
- expanded, the count is back on the Inbox alone

## 28. An AI agent

Screenshots: `agents-1-before`, `agents-2-connect`, `agents-3-after`, `agents-4-send`, `agents-5-outbox`, `agents-6-window`

The test's agent is `scripts/ui-e2e/agent.mjs`, run from a copy of Node.js named "My AI agent": it starts the app's `--mcp` relay as an agent host would, and runs one conversation through it. Two new unread messages are added first.

- a program whose agent connects for the first time is asked about
- the question names the program
- reading and organizing are offered, sending is not
- allowed, the agent connects
- with the tools of what it may do
- it reads a message as text, told it is the sender's, without marking it read
- it marks two messages read
- on the server
- and in the window at once
- a message the agent wants to send is shown to the user first
- every recipient by address, the new ones marked
- with a warning about the new address
- Send waits a moment before it can be pressed
- the agent learns the user said yes
- it waits in the Outbox, where it can still be deleted
- Tools > AI Agents opens
- it lists the program and what it may do
- and what its agent did, newest first
- Undo takes the message back
- and the Outbox is empty

## 29. Marking all read

Screenshots: `organize-5-all-read`

- the Inbox has unread messages
- Edit > Mark All Read: none unread in the folder
- and none on the server

## 30. Dragging a message onto a folder

- a message dragged onto Archive is moved there
- and out of the Inbox
- and out of the list
- with Ctrl it is copied there
- and stays in the Inbox
- dropped on its own folder, it stays

## 31. Several messages

Screenshots: `select-1-several`, `select-2-undo`

- Ctrl+click (Command+click on the Mac) adds two more messages: three are selected
- the reading pane says 3 messages are selected, and how many of them are unread
- the status bar says 3 selected
- Reply is off for several, Mark as Read is on
- Mark as Read marks the three read on the server
- Move to Folder moves the three to Archive
- and out of the list
- the status bar says they were moved to Archive
- Edit > Undo Move brings them back to the Inbox
- and on the server
- Select All selects every message of the list
- one message selected again is shown in the reading pane

## 32. Messages as files

Screenshots: `files-4-drag-out`, `files-5-forward`, `files-6-drop-in`

The system's drag and file panels run outside the app: each test gives the drop and the panels their answer through the platform's own drag data (what Explorer, Finder or the file manager would read from it).

- three messages dragged out of the list become three .eml files where they are dropped, named after their subjects
- with what each message is, byte for byte
- one not downloaded yet is downloaded for it
- Save As with three selected asks for a folder and saves the three there, never over a file that is there
- Forward with three selected writes one new message with the three attached as .eml files
- its subject is the first one's, with Fw:
- .eml files dropped onto Archive in the folder tree are put in it, on the server
- a file that is not a message is turned away

## 33. Flag colours

Screenshots: `flags-1-colors`

- Message > Flag has the seven colours of Apple Mail and Clear Flag
- Orange flags the message orange: `\Flagged` and `$MailFlagBit0` on the server
- the flag column shows it in orange
- Blue on two selected messages flags both blue: `$MailFlagBit2`
- a message flagged purple by another program (Apple Mail) shows a purple flag
- Clear Flag takes the flag and its colour away on the server

## 34. Junk and not junk

Screenshots: `organize-7-junk`

- the toolbar has Junk in the Inbox
- Junk moves the message to Junk E-mail
- and out of the Inbox
- in Junk E-mail the toolbar has Not Junk in its place
- the search field is still drawn over the toolbar (edge $edgePixel, inside $insidePixel)
- Not Junk moves it back to the Inbox

## 34a. Archive

Screenshots: `organize-8-archive`

- Archive is on for a message of the Inbox
- Archive moves the message to Archive on the server
- and out of the Inbox
- the status bar says it was archived
- Undo puts it back in the Inbox

## 34b. Empty Folder

Screenshots: `organize-9-empty`

- a message is put into Junk on the server
- Empty Folder asks first, saying how many go
- Junk E-mail is empty on the server
- and in the list

## 34c. A message in a window of its own

Screenshots: `read-16-window`

- Enter on a message of the Inbox opens it in a window of its own, titled with its subject
- the window shows the message, and it is marked read on the server
- Next shows the message after it in the list, and the title follows
- Previous goes back
- Reply in the window opens a reply to that message
- closing the window leaves the main window as it was

## 34d. Reading with the keyboard

Screenshots: `read-17-find`, `read-18-go-to`

- Next Message selects the message below in the list, Previous Message the one above
- Next Unread Message selects the next unread message
- with none left in the folder it asks to go on to the next folder with unread mail, and Yes goes there
- Go to Folder shows the folders of every account, and typing narrows them
- choosing Sent Items there shows Sent Items
- Find in This Message finds a word of the message shown, and says when it is not there

## 34e. Conversations

Screenshots: `threads-1-collapsed`, `threads-2-expanded`, `threads-3-options-off`

- three messages of one conversation (replies naming the first in References) are put into the Inbox on the server
- the Inbox lists the conversation once, on its first message, with the count of its messages, bold while one is unread
- expanding it shows its replies under it, indented
- collapsing it hides them again
- Mark Read on the collapsed row marks all three read on the server
- with Group messages by conversation turned off in Options, the list has the three messages each on a row of its own
- turned on again, the conversation is one row again

## 34f. A message that bounced

Screenshots: `bounce-1-failed`, `bounce-2-delayed`, `bounce-3-list`

- a message is put into Sent Items on the server, and a delivery report saying it could not be delivered to one recipient (the mailbox does not exist) into the Inbox
- the report's row in the Inbox has the undelivered mark in the attachment column's place
- opening it shows the card above the message: not delivered, the recipient, why and what to do
- the card's Details show the server's own words
- Show the message that bounced selects the message in Sent Items
- a notice that delivery is delayed shows the amber card, saying it is still being tried
- searching for `is:bounce` finds the two notices and nothing else

## 34f2. A one-time code

Screenshots: `otp-1-card`

- three read messages are put into the Inbox, dated hours ago: one with a code in its text, from a domain the provider's
  Authentication-Results say signed it (`dkim=pass`); one with an `OTP-Token` header for a domain that signed it; one
  with a code in its text and no verdict
- opening the first shows a card above it: "Code from" the sender's domain, the code, where to enter it, and that it has
  probably expired (it is older than an hour)
- Copy on the card puts the code on the clipboard, and the status bar says so
- the second's card has the header's code and the domain of its origin
- the third has no card
- Options (Settings on the Mac, Preferences on Linux) has Show sign-in codes in new mail notifications, off at first;
  turned on, the core is told (the core's own test checks that the notification then names the code of fresh, signed
  mail and not of unsigned mail)

## 34g. Watch and Ignore Conversation

Screenshots: `threads-4-watch`, `threads-5-ignore`

- the list has no Watch or Size column, and Subject is its widest column
- Message > Watch Conversation on the conversation of 34e checks the menu item, in the Message menu and in the message's
  right-click menu
- a new reply to it is put into the Inbox on the server, and it is announced (the notification says the conversation is
  watched)
- Watch Conversation again takes the check marks away
- Message > Ignore Conversation (K in the list) on another conversation turns its row grey, checks the menu item in both
  menus, and marks its messages read on the server
- a new reply to it is put into the Inbox on the server: it arrives read on the server, without a notification
- View > Hide Ignored Conversations leaves the ignored conversation out of the list; turned off again, it is back

## 35. Folders

Screenshots: `folders-2-tree`, `folders-3-delete`, `folders-4-inbox`

- $title asks for a name
- New Folder makes Archive/Projects on the server
- and it is in the tree
- Rename renames it on the server
- deleting a folder asks first
- and Yes deletes it on the server
- renaming the Inbox is refused with the reason

## 36. Closing a message that was written

Screenshots: `write-6-close`

- closing asks before throwing the text away
- No closes it
- without saving it

## 37. An e-mail link

Screenshots: `write-18-mailto`

- a second start with a mailto: link hands it over and ends
- the running app opens a new message from it

## 38. Completing an address

Screenshots: `write-17-complete`

- typing in To lists the people it may be
- with someone heard from
- Enter takes the first, with a comma for the next
- and closes the list

## 39. A signature

Screenshots: `signature-1-editor`, `signature-2-new`, `signature-3-reply-left`

- File > Accounts opens the accounts
- Signature opens the signature editor of the account
- titled with the account
- the signature editor takes typing
- OK saves it and closes the editor
- a new message takes typing above the signature
- the message went with the signature
- a reply takes typing
- a reply has the signature above the quote

## 39a. The Address Book

Screenshots: `contacts-1-book`, `contacts-2-person`, `contacts-3-group`, `contacts-4-pick`, `contacts-5-import`

- Tools > Address Book (Ctrl+Shift+B) opens the Address Book, empty, with New Contact, New Group, Properties, Delete and Write To
- New Contact opens Contact Properties
- with Mary Smith's first and last name and two addresses, mary@example.com and mary.smith@work.example, the first the default
- OK saves the contact and the book lists it: Mary Smith, mary@example.com
- the find box finds her by "smi" and lists no one for "zed"
- New Group opens Group Properties
- named Team, with Mary Smith from Select Members and dave@example.com typed
- OK saves the group, and it is listed on the left with its two members
- in a new message, To opens Select Recipients
- it lists the group and the contact
- the group and the contact picked with To -> go to the message's recipients
- OK puts them in To: Mary Smith <mary@example.com>, dave@example.com, each address once
- typing "tea" in Cc offers the group by its name
- taking it puts its members in Cc
- the message is closed without saving
- Add Sender to Address Book (Tools, and the message list's right-click menu) on a message adds its sender to the book, and on it again says the sender is there already
- and again says the sender is in the Address Book already, without a second card
- File > Import Address Book reads a vCard file of two contacts, Mary Smith (mary@example.com) and John Doe (john@example.org)
- it says it added 1 and skipped 1 already in the Address Book
- and the book lists John Doe beside Mary Smith and Sender
- File > Export Address Book writes a vCard file
- with Mary Smith, John Doe and Sender in it
- Delete in the Address Book asks first, then removes the selected contact

## 40. A Gmail address

Screenshots: `account-5-app-password`, `account-6-gmail`

- without it, Gmail wants an app password, and that is said
- with Google turned off, a Gmail address goes to the app password way
- its servers were found

## 41. A wrong password

Screenshots: `trouble-1-password`

The second account is on a second ImapKit server (`second` in the harness configuration), as ImapKit's users share one mailbox.

- a refused password is asked for again
- the status bar says why
- with the right password typed, the account syncs

## 42. All Inboxes

Screenshots: `all-inboxes-1-list`, `all-inboxes-2-menu` (not yet on the Mac: the test checks the menu's items there without a picture of it)

- All Inboxes is at the top of the tree, above the accounts
- it lists the mail of both accounts' Inboxes
- newest first, the two accounts' messages among each other
- the Account column names the account of each
- the status bar counts both Inboxes
- its right-click menu has Mark All Read alone
- a reply goes from the account of the message
- Mark All Read marks both Inboxes read on the servers

## 42a. All Inboxes by account, account names, the account's menu

Screenshots: `all-inboxes-3-accounts`, `account-menu`

- the first account kept the account name Add Mail Account offered from its address ("inboxclassic.test"); the second was named "Work" there
- All Inboxes has a row for each account under it, in the accounts' order, named as the account is
- each row shows its Inbox's unread count
- the second account's row lists that account's Inbox alone (the first account's message is not in it)
- the folder bar names the Inbox and the account ("Inbox - " and the account's name)
- All Inboxes again lists both accounts' Inboxes
- the second account's Properties has the Account name field, filled with its name; set to "Second", the account's heading and its row under All Inboxes say "Second"
- the first account's right-click menu has Send and Receive, Mark All Read, New Folder and Properties
- its Mark All Read marks every folder of the first account read on the server, the second account's mail stays unread
- its Properties opens that account's Properties

## 43. Moving between accounts

Screenshots: `move-1-dialog`, `move-2-accounts`

With the second account still there:

- Move to Folder shows the folders of both accounts in a tree, with a filter box
- the folder the message is in is shown but can not be chosen
- the button says Move
- typing in the filter narrows the tree to the folders that match
- a message of the first account moved to the second account's Archive leaves the list at once
- the status bar says how far the move is
- it is in the second account's Archive on its server, with its flags
- and gone from the first account's server
- Edit > Undo Move brings it back to the first account
- Copy to Folder copies a message to the second account's Archive and keeps it in the Inbox
- the next Move to Folder offers Archive of the second account under Recent
- a message dragged onto a folder of the second account is moved there

## 44. Accounts

Screenshots: `accounts-1-list`, `accounts-2-properties`, `accounts-unexpected`, `accounts-3-after`

- File > Accounts lists the accounts
- both accounts are listed
- Properties shows the settings
- with the IMAP port as it was saved
- OK closes Properties
- the new name is saved
- Remove (or Delete) asks first
- and removes it
- the account leaves the tree
- All Inboxes goes with the second account

## 45. Sign-in apps

Screenshots: `signin-1-apps`, `signin-2-google-preset`, `signin-3-check` (not yet on the Mac, not yet on Linux), `signin-4-editor` (not yet on Linux), `signin-5-apps-added`, `signin-6-first-page` (not yet on the Mac, not yet on Linux), `signin-7-why` (not yet on the Mac, not yet on Linux), `signin-8-more` (not yet on the Mac, not yet on Linux), `signin-9-waiting`, `signin-10-added` (not yet on the Mac, not yet on Linux), `signin-11-in-use` (not yet on the Mac, not yet on Linux), `signin-12-toggled`, `signin-13-properties` (not yet on the Mac, not yet on Linux), `account-5b-browser-sign-in` (not yet on the Mac, not yet on Linux)

- File > Accounts > Sign-in Apps opens the sign-in apps
- the built-in Microsoft and Google clients are listed
- Microsoft is on and Google off out of the box
- a built-in client can not be edited or removed
- a built-in client says what it is
- Add opens the sign-in app editor
- Fill in for Google fills in its issuer
- its servers, and the redirect URI to register
- the redirect URI follows the issuer
- OK saves the sign-in app
- it is listed, turned on
- Sign in with Google is shown turned off
- Sign in with Microsoft works
- the reason is under it, without hovering
- Why? says why it is off
- More sign-in options opens a menu
- with the sign-in app, a separator and Add a sign-in app
- the provider sends the browser back to the app, which says it is signed in
- the account signed in to is added, and its folders sync with the token
- a sign-in app an account uses is not removed, naming the account
- Google turned on, the sign-in app off
- Sign in with Google works once turned on
- a sign-in app turned off is left out of More sign-in options
- a Gmail address is offered Sign in with Google

## 46. Options and the language

Screenshots: `options-1-language`, `lang-1-german`, `lang-1b-german-form`, `lang-1c-french-form`, `lang-2-pseudo-main`, `lang-3-pseudo-form`

- Tools > Options (Settings on the Mac, Preferences on Linux) has Language and Notify of New Mail
- Language lists System default, with the language it is now, and English, Deutsch, Eesti, Español and Français by their own names
- a language chosen says the app starts again to change it, with Restart Now and Later
- started in German, the menus, the toolbar and the status bar are in German
- and the special folders, Archive among them (Posteingang, Archiv)
- Add Mail Account in German (and French on the Mac): the Google and Microsoft sign-in buttons say it in the language, the form as wide as they are
- started in the pseudo-language, nothing in the main window, the compose window and the account form is left in English
- and nothing is cut off
- in each language of the catalogs (de, es, et, fr), the main window, a new message, Add Mail Account, the accounts and Preferences, nothing cut off in them: `tour-<language>-<n>-<view>` (Linux)

## 47. About

Screenshots: `help-1-about`

- About shows the version

## 48. Help

Screenshots: `help-2-contents`, `help-3-search` (Windows, Linux), `help-4-topic`

- F1 (Command-? on the Mac) opens the help at the main window's topic; a dialog's F1 or help button opens its own
- the contents list the sections and their topics (Windows, Linux: in the help window; the Mac: the Help Book's first page, whose bundle has every language's pages and search index)
- a search for "junk" lists the topics with that word (Windows, Linux)
- a link to another topic opens it, and Back returns to the one before

## 49. Printing

Screenshots: `files-3-print-missing`, `files-3-print`

- Print opens the print preview in a window over the app
- as wide as the app
- and closing it prints nothing

## 50. The tray

Screenshots: `tray-1-notification`, `tray-2-taskbar` (not yet on the Mac, not yet on Linux)

- the app has its icon in the notification area
- closing the window hides it in the tray
- and the app keeps running
- a click on the icon shows the window again
- with the new message in the list, which came without a sync

## 51. Closing

Screenshots: `write-12-close-app`

- closing the app asks about a message with changes
- Cancel keeps the app and the message open
- No closes the message without saving, and the app
