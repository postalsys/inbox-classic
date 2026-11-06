# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-flag-menu = Fla&g
win-still-running-detail = It keeps checking for new mail here. Click the icon to open it, or right-click it to exit.
win-new-messages = { $count ->
    [one] { $count } new message
   *[other] { $count } new messages
}
win-default-app-not-installed = This copy of Inbox Classic was not installed, so Windows does not list it as a mail app. Install it to choose it.
win-default-app-settings = Windows opens its Default apps settings for Inbox Classic. Choose it for MAILTO there.
win-no-unread = No unread messages
win-unread-messages = { $count ->
    [one] 1 unread message
   *[other] { $count } unread messages
}
win-print-failed = The message could not be printed.
win-print-title-of = Print - { $subject }
win-no-bodies = Message bodies can not be shown.
win-webview-failed = Creating the WebView2 failed.
win-webview-missing = The WebView2 runtime is not available.

## Buttons and words used in many windows

win-delete-button = &Delete
win-find-label = &Find:
win-col-to = To
win-save-as-button = Save &As...
win-too-many-files = Too many files at once: choose fewer.

## The Outbox

win-outbox-send-all = &Send All Now

## The compose window

win-editor-failed = Messages can not be written.
win-ctrl-click-to-open = ({ $ctrl }+click to open)
win-remove-file = &Remove
win-format-bold = Bold ({ $ctrl }+B)
win-format-italic = Italic ({ $ctrl }+I)
win-format-underline = Underline ({ $ctrl }+U)
win-format-link = Hyperlink ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Signature: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] No results for “{ $words }” in all folders
    [one] { $count } result for “{ $words }” in all folders
   *[other] { $count } results for “{ $words }” in all folders
}
win-search-found-in = { $count ->
    [0] No results for “{ $words }” in { $folder }
    [one] { $count } result for “{ $words }” in { $folder }
   *[other] { $count } results for “{ $words }” in { $folder }
}
win-search-indexing = { $count ->
    [one] still indexing the text of { $count } message
   *[other] still indexing the text of { $count } messages
}
win-no-match-indexing = { $count ->
    [one] The text of { $count } message is still being indexed, so more may be found soon.
   *[other] The text of { $count } messages is still being indexed, so more may be found soon.
}
win-files = { $count ->
    [one] { $count } file
   *[other] { $count } files
}
win-click-to-retry = Click here to try again.
win-save-attachments = &Save Attachments...
win-files-not-saved = { $failed } of the { $count } files could not be saved.
win-attendees = { $count ->
    [one] { $count } attendee
   *[other] { $count } attendees
}
win-copy-button = &Copy
win-move-button = &Move
win-new-folder-in-highlighted = The new folder goes in the highlighted folder.
win-delete-folder-ask = Delete the folder "{ $folder }" with its messages and the folders in it? It is deleted on the server too.
win-clear-flag = &Clear Flag
win-rename = &Rename...
win-open = &Open
win-view-source = View &Source
win-properties = Propert&ies
win-messages-not-saved = The messages could not be saved.
win-messages-not-forwarded = The messages could not be forwarded.

## Accounts

win-sign-in-google = Sign in with Google
win-sign-in-microsoft = Sign in with Microsoft
win-next = &Next >
win-your-account = your account
win-browser-sign-in = (browser sign-in)
win-add = &Add...
win-properties-button = &Properties...
win-signature-button = Si&gnature...
win-sign-in-apps-button = Sign-in A&pps...

## AI agents

win-allow = &Allow
win-dont-allow = &Don't Allow
win-turn-away = &Turn Away
win-col-address = Address
win-never-written-to = Never written to
win-send = &Send
win-edit-first = &Edit First
win-dont-send = &Don't Send
win-forget-program-ask = Forget this program and what its agents did? It is asked about again the next time it connects.
win-clear-log-ask = Clear the list of what agents did? What they did stays done.
win-let-agents-connect = &Let AI agents connect to Inbox Classic
win-agent-programs = &Programs whose agents asked to use your mail:
win-change = &Change...
win-what-agents-did = &What agents did:
win-clear = C&lear
win-how-to-connect = How to connect an agent

## Sign-in apps

win-check-button = C&heck
win-copy = &Copy
win-built-in = (built-in)
win-edit = &Edit...

## Options

win-options-language-label = &Show Inbox Classic in:
win-options-restart-note = Inbox Classic restarts to show another language.
win-options-notify = &Notify me when new mail arrives
win-restart-ask = Inbox Classic shows { $language } once it restarts. Restart now?
win-restart-now = &Restart Now
win-restart-later = &Later
