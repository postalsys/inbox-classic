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

## 6. Pictures from the internet

Screenshots: `read-2-pictures`

- clicking the bar shows the pictures, and the bar goes away

## 7. Saving the attachment

Screenshots: `read-3-attachments` (not yet on the Mac), `read-4-save` (not yet on the Mac, not yet on Linux), `read-4-save-failed`

- the paper clip offers the files to save
- choosing one asks where to save it
- the attachment is saved as it was sent
- and marked as from the internet

## 8. Marking unread and read

Screenshots: `read-5-unread`

- Mark Unread clears \Seen on the server
- Mark Read sets it again

## 9. A reply with the earlier message folded

Screenshots: `read-6-folded`

## 10. Forwarding

Screenshots: `write-1-forward`

- Forward opens a compose window
- the subject is marked Fw:
- the recipients are left to the user

## 11. Replying to all

Screenshots: `write-2-reply-all`

- Reply All opens a compose window
- it goes to the sender and the others
- but not to the account itself
- with the Cc kept
- the Cc row is open, as it has someone in it

## 12. Replying

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

## 13. A new message

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

## 14. Pictures dropped into the text

Screenshots: `write-13-dropped-picture` (not yet on the Mac, not yet on Linux)

- the editor takes typing
- a file that is no picture is attached
- the message with the dropped picture was sent
- the picture went inline, as a cid: part, like Insert Picture puts one
- with no data: URI left in the HTML
- the other file went as an attachment, the picture not

## 15. Links in a message being written

Screenshots: `write-14-link-status` (not yet on the Mac, not yet on Linux), `write-15-edit-link` (not yet on the Mac, not yet on Linux), `write-16b-unlinked`

- the Link button asks for an address
- with the cursor in a link, the status bar shows its address
- the Link button on a link shows its address to change
- and changes it
- the dialog shows the changed address
- an empty address removes the link
- the link text went, without the link

## 16. A message that is not downloaded yet

Screenshots: `read-13-downloading`, `read-12-not-downloaded`

- the header shows the message's sender and subject at once, from the list
- the pane says the message is being downloaded
- a message that can not be downloaded says why, with Try Again
- once the account is back the message shows by itself
- and Try Again goes

## 17. The Outbox: a send that can not go

Screenshots: `write-7-outbox`

- there is no Send Later: Send sends
- Send closes the message
- a send that can not go says it waits in the Outbox
- and it was not sent
- Tools > Outbox lists what waits
- the message is in it
- once the server is back it goes by itself

## 18. Drafts

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

## 19. Send/Recv

Screenshots: `main-2-new-mail`, `main-3-sent-items`

- the new mail is in the list
- Sent Items has what was sent

## 20. Finding

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

## 21. Saving and importing a message as a file

- Save As asks where, with the subject as the name
- and saves the message as it came
- Import Messages asks for files
- and puts the message in the folder, on the server

## 22. Flagging, deleting and moving

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

## 23. Unsubscribing

Screenshots: `read-8-unsubscribe`, `read-9-unsubscribe-ask`

- a message of a mailing list has Unsubscribe in its header
- it asks first, naming where it goes
- and the status bar says it is done

## 24. A calendar invitation

Screenshots: `read-10-invitation`

- a message with an invitation shows the event over the text, with Open in Calendar

## 25. A brand logo (BIMI)

Screenshots: `read-11-logo`

- a sender whose logo the server passed has it beside the header

## 26. Marking all read

Screenshots: `organize-5-all-read`

- the Inbox has unread messages
- Edit > Mark All Read: none unread in the folder
- and none on the server

## 27. Dragging a message onto a folder

- a message dragged onto Archive is moved there
- and out of the Inbox
- and out of the list
- with Ctrl it is copied there
- and stays in the Inbox
- dropped on its own folder, it stays

## 28. Junk and not junk

Screenshots: `organize-7-junk`

- the toolbar has Junk in the Inbox
- Junk moves the message to Junk E-mail
- and out of the Inbox
- in Junk E-mail the toolbar has Not Junk in its place
- the search field is still drawn over the toolbar (edge $edgePixel, inside $insidePixel)
- Not Junk moves it back to the Inbox

## 29. Folders

Screenshots: `folders-2-tree`, `folders-3-delete`, `folders-4-inbox`

- $title asks for a name
- New Folder makes Archive/Projects on the server
- and it is in the tree
- Rename renames it on the server
- deleting a folder asks first
- and Yes deletes it on the server
- renaming the Inbox is refused with the reason

## 30. Closing a message that was written

Screenshots: `write-6-close`

- closing asks before throwing the text away
- No closes it
- without saving it

## 31. An e-mail link

Screenshots: `write-18-mailto`

- a second start with a mailto: link hands it over and ends
- the running app opens a new message from it

## 32. Completing an address

Screenshots: `write-17-complete`

- typing in To lists the people it may be
- with someone heard from
- Enter takes the first, with a comma for the next
- and closes the list

## 33. A signature

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

## 34. A Gmail address

Screenshots: `account-5-app-password`, `account-6-gmail`

- without it, Gmail wants an app password, and that is said
- with Google turned off, a Gmail address goes to the app password way
- its servers were found

## 35. A wrong password

Screenshots: `trouble-1-password`

- a refused password is asked for again
- the status bar says why

## 36. Accounts

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

## 37. Sign-in apps

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

## 38. About

Screenshots: `help-1-about`

- About shows the version

## 39. Help

Screenshots: `help-2-contents`

- F1 opens the help

## 40. Printing

Screenshots: `files-3-print-missing`, `files-3-print`

- Print opens the print preview in a window over the app
- as wide as the app
- and closing it prints nothing

## 41. The tray

Screenshots: `tray-1-notification`, `tray-2-taskbar` (not yet on the Mac, not yet on Linux)

- the app has its icon in the notification area
- closing the window hides it in the tray
- and the app keeps running
- a click on the icon shows the window again
- with the new message in the list, which came without a sync

## 42. Closing

Screenshots: `write-12-close-app`

- closing the app asks about a message with changes
- Cancel keeps the app and the message open
- No closes the message without saving, and the app
