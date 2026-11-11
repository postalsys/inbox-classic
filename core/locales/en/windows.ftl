# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic keeps checking for new mail in the background. Click the icon to open it. To exit, right-click the icon and use its menu.
win-default-app-not-installed = This copy of Inbox Classic was not installed, so Windows does not list it as a mail app. Install it to choose it.
win-default-app-settings = Windows will open its Default apps settings. Choose Inbox Classic to open MAILTO links.
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
win-save-as-button = Save &As...
win-too-many-files = Too many files at once: choose fewer.

## The Outbox


## The compose window

win-editor-failed = Messages can not be written.
win-ctrl-click-to-open = ({ $ctrl }+click to open)
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
win-new-folder-in-highlighted = The new folder will be created inside the selected folder.
win-delete-folder-ask = Delete the folder “{ $folder }” with its messages and the folders in it? It is deleted on the server too.
win-rename = &Rename...
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

win-dont-allow = &Don’t Allow
win-col-address = Address
win-never-written-to = Never written to
win-send = &Send
win-dont-send = &Don’t Send
win-forget-program-ask = Remove this program, its permissions and its agents’ activity history? You will be asked for permission again the next time it connects.
win-clear-log-ask = Clear the agents’ activity history? This will not undo changes made by the agents.
win-agent-programs = &Programs whose agents have requested access to your mail:
win-change = &Change...
win-what-agents-did = Agent &activity:
win-how-to-connect = How to connect an agent

## Sign-in apps

win-built-in = (built-in)
win-edit = &Edit...

## Options

win-options-language-label = &Show Inbox Classic in:
win-options-restart-note = Restart Inbox Classic to change the language.
win-options-notify = &Notify me when new mail arrives
win-restart-ask = Inbox Classic shows { $language } once it restarts. Restart now?
