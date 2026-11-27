# The conversation view, second round

The whole conversation in the reading pane (#265, released in 0.22.0) is hard to read and to use: what is open and what is folded looks alike, a click on an open message folds it, and the lines are small targets. This is the plan from the review of 2026-11-26 (screenshots of the three apps from CI, the page's markup rendered for a read thread, mixed states, a 50-message thread, a narrow pane and every message open, and a trace of the click rules in `pe-core/src/conversation.rs`). Nothing here is built yet.

## What the review found

1. **Open and folded look alike.** A folded line and an open message's header are the same row; the only difference is a faint grey tint. Nothing says a row can be opened.
2. **A click on an open message folds it.** `Conversations::click` opens a folded message and gives it the focus, but folds an open one. There is no way to make an open message the one Reply acts on without folding and opening it again. Folding the focused one moves the focus to the nearest open message without a word.
3. **Small targets.** A folded line is about 27 px tall, each in its own box, with 6 px between them where a click does nothing. Only the header strip of an open message takes a click; its body does not.
4. **The Reply target is a guess.** It is a 2 px border in the blue of the unread dot. The header block above the stack (From, Date, To, Subject) belongs to that message and changes when it does, repeating what its card says.
5. **Dates crowd the lines.** "Thursday, November 26, 2026, 9:02 AM" on every line takes a third of it, before the first words.
6. **Long conversations are a wall.** Up to 20 identical lines in a row; the view opens scrolled to the top, so the starting message can be below the fold (the apps keep the scroll on a rebuild but nothing scrolls to the focus).
7. **A folded line does not say it has attachments**, and attachments, the pictures bar and the reactions row belong to the focused message only.
8. **No keys.** The lines are reached with Tab inside the web view only.
9. **Your own messages** carry your full name and a "Sent Items" chip, so the back and forth is hard to follow.

## Decisions (the user's, 2026-11-26)

- **Click model**: a disclosure arrow at the start of each line. A click on a folded line opens and selects it. A click on an open message, header or body, only selects it. The arrow folds (and opens).
- **Reply target**: the selected message is marked by its frame, each app in its own native look (the review of 2026-11-27):
    - Windows, the classic look: the pane sunken as the tree and the list beside it, on the button face's gray. A message alone is Outlook Express's preview pane: its header a gray band across the pane with the subject, its body under a line from edge to edge. In a conversation each message's header is on the gray and its body in a sunken white well; the selected one has an etched frame, as a group box; folded messages are rows in one sunken white box, as a list.
    - The Mac, as Mail: white cards with a hairline on a soft gray of the stack's own (the window's background is white since macOS 26), the selected card's outline faintly in the accent colour, the buttons at the header's trailing edge.
    - Linux, as GNOME: libadwaita's `.card` on the window's background, the selected card ringed faintly in the accent colour; no coloured bar or tinted header.
    - A message alone has no card on the Mac and Linux, just a line under its header; its subject stays above it (the stack scrolls to the selected message only when it starts below the first screen). Every open message has its own Reply, Reply All and Forward buttons in its header. The toolbar and the keys act on the selected one.
- **Header block**: in a conversation it shows the conversation: its subject once, "7 messages, 2 unread", and the people in it. Each open message shows its own From, To, Cc and full date in its card.
- **Lines**: folded lines join into one bordered list with hairlines between them and no gaps, about 36 px tall, a target across their whole width. Dates as the message list writes them; the full date in the open card and on hover.
- **Long conversations**: the first message, one row for the read ones in between ("14 earlier messages"), the last two read messages, and everything unread or selected. A click on the row lists them all. The view scrolls to the starting message when it opens.
- **Your own messages** read "You" (translated). The folder chip stays for messages outside the list's folder, quieter; "Draft" stays.
- **Keys**: next and previous message of the conversation; Left and Right fold and open the selected message; commands that open and fold every message of the conversation.
- **Extras**: a paperclip on folded lines and each open message's own attachments in its card; a More menu a message (Print, Mark Unread, Delete, Open in Window, View Source); the sender's picture or initials on each line; a double-click on a line opens that message in a window.

## How it is built

**Real native frames** (the user's decision of 2026-11-26, after looking at how Apple Mail shows a conversation): the stack is no longer one web page. Each app draws it with its own controls, and only a message's body is a web view.

- **The core gives data, not a page.** `pe-html`'s conversation page goes away. The C API (and `pe-core` for Linux) gives the conversation as a list: for each message who (or "You"), the short and the full date, the first words, To and Cc, its folder and state words, unread, open, selected, its attachments, its picture, its reactions; and the summary for the header (subject, counts, people). Operations: select, open, fold, open all, fold all, show the collapsed middle. Each open message's document is the sanitized document a message alone has, asked for by its place. Every string and decision stays the core's; the apps show values.
- **The rules** (`pe-core/src/conversation.rs`): `click` splits into select, fold and open; the plan collapses a run of read messages in the middle (the first message, the last two read, the unread and the selected stay); short dates (`calendar` has the list's form); "You" for the user's own addresses.
- **The stack in each app**: a native scrolling column. A folded message is a native row (arrow, picture, name, chips, first words, paperclip, reactions, date). An open one is a native frame: its header (arrow, picture, name, Reply, Reply All, Forward, More, then To, Cc and the full date), a web view of its body as tall as its content, and its attachments. A sent message carries its folder as a quiet strip, as Apple Mail's "Found in Sent". Windows: Win32 controls in the classic look (square frames, the system's colours and font, a real context menu for More). The Mac: AppKit views in the style of Apple Mail's cards. Linux: GTK 4 and libadwaita rows and cards.
- **One web view an open message.** A body is sized to its content (the measuring the apps do today for frames) and never scrolls by itself: the wheel and the keys scroll the stack. Web views are made as their frames come near the visible part and let go when far from it, their heights remembered, so a long conversation with many open messages does not hold them all.
- **Selecting is native now.** A click anywhere in a frame, its body included, selects it: the app knows which web view took the click, so the page no longer has to be asked.
- **What changes with it**: Find in This Message searches the selected message; Select All and a text selection stay inside one message; Print Conversation is unchanged (the core's own document); the pictures bar, the sender check label and the code card belong to each frame.
- **Budgets, checked in the UI tests**: a conversation of 50 messages with 20 open shows its first frame and scrolls without a stall on all three; memory with 20 open stays within a stated bound of one message's. Set from measurements in the first step; a platform that misses them caps how many bodies are live at once.
- **Commands** (`core/commands.toml`): Next Message in Conversation, Previous Message in Conversation, Open All Messages, Fold All Messages (named apart from the list's Expand All and Collapse All Conversations). Alt+Down and Alt+Up move; Left and Right act when the stack has the keyboard.
- **Accessibility**: native controls bring their roles: the arrow a disclosure button, the rows a list, the selected frame announced; every target at least 32 px tall; the accent never the only sign.

### What native frames cost

- Three implementations of the stack instead of one page, each with its own layout, scrolling and focus code, and three sets of UI test steps.
- The wheel over a body must scroll the stack: WebView2, WKWebView and WebKitGTK each take the wheel for themselves and each need their own handling.
- WebView2 is the heaviest: every open message is a browser view. The lazy making and letting go above is what keeps a long conversation usable; it is the main risk on Windows.
- Roughly twice the work of restyling the page, most of it in the first step.

## Decided in the second round (2026-11-26)

- **A message alone uses the same frame**, a conversation of one. The old From, Date, To, Subject block goes away on all three apps; the reading pane has one look.
- **Open at first**: the unread messages and the starting one, as today; the read ones folded.
- **Signed and encrypted messages show in the stack.** The frame's web view holds the page such a message has when shown alone (`secure_page`: the core's labels, each protected part a document of its own), so the rules of OpenPGP hold as they are: labels and mail never share a document, a decrypted part's pictures load only on a click for that message and are never remembered, and replies quote only what was shown. "Opens by itself" (`ui-conversation-alone`) goes away.
- **Pictures**: one bar for the conversation; it loads the pictures of every open message whose sender would be allowed. Decrypted messages are never part of it.
- **The middle collapses** at a run of four or more read messages between the first message and the last two read ones.
- **Keys**: Alt+Down the next message of the conversation, Alt+Up the previous (Option on the Mac); Left and Right fold and open the selected message when the stack has the keyboard; Open All Messages and Fold All Messages in the menu without keys.
- **If many open messages are slow**: only the bodies near the visible part are live; the others are made again when scrolled to, their heights remembered. No limit on how many messages are open.
- **Other folders**: a quiet folder chip on a folded row; an open frame has a strip on top ("Found in Sent Items"); a draft says Draft and its frame offers Edit.

## To settle while building

- Alt+Down and Alt+Up checked free in every window and layout on the three platforms (lists and menus use them in places); if one is taken, it comes back to the user.
- The accent, the strip and the rows in dark mode and in the Windows classic look, from screenshots.

## Order of work

All three steps landed in one pull request: the frames' own buttons, files and pictures and the four commands came with the native stack, as the stack needed them to be usable at all.

Each step lands on all three apps with its tests, the UI test's step and screenshots, the help in every language (translations marked for review), `/simplify`, `/security-review`, and a UX review from screenshots until nothing is left.

1. **The native stack**: the core's conversation as data and its new rules; on each app the rows, the frames with a web view a body, scrolling, selecting, the arrows, short dates, "You", the collapsed middle, scrolling to the start, the header block's conversation form; the budgets measured and set. The page of `pe-html` is removed with it.
2. **Each message's own things**: Reply, Reply All, Forward and More in each frame, attachments on rows and in frames, pictures, Open in Window on a double-click.
3. **Keys and commands**: next and previous message, fold and open, Open All and Fold All.
