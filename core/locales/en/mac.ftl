# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.

## The app and its menus

mac-quit = Quit Inbox Classic
mac-settings = Settings…
mac-services = Services
mac-hide = Hide Inbox Classic
mac-hide-others = Hide Others
mac-show-all = Show All
mac-check-updates = Check for Updates…
mac-close-window = Close Window
mac-redo = Redo
mac-cut = Cut
mac-paste = Paste
mac-menu-window = Window
mac-minimize = Minimize
mac-zoom = Zoom
mac-no-updates = This version of Inbox Classic does not support automatic updates. Download the latest version from inboxclassic.com.

## Settings

mac-settings-title = Settings
mac-language-label = Language:
mac-restart-hint = Restart Inbox Classic to change the language.
mac-notify-new-mail = Notify me when new mail arrives
mac-restart-question = Restart Inbox Classic now to change the language?

## Dialogs

mac-choose = Choose

## The main window

mac-still-running-detail = Inbox Classic keeps checking for new mail in the background. Click its icon in the Dock to open the app.
mac-outbox-waiting =
    { $count ->
        [one] { $count } message in the Outbox
       *[other] { $count } messages in the Outbox
    }
mac-sending = Sending { $subject }…
mac-checking = Checking for new messages on { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = This copy of Inbox Classic is not an app bundle, so it can not be the default mail app.
mac-not-made-default = Inbox Classic was not made the default mail app: { $reason }
mac-tool-search = Search

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] The text of { $count } message is still being indexed, so more may be found soon.
       *[other] The text of { $count } messages is still being indexed, so more may be found soon.
    }
mac-results-everywhere =
    { $count ->
        [0] No results for “{ $words }” in all folders
        [one] { $count } result for “{ $words }” in all folders
       *[other] { $count } results for “{ $words }” in all folders
    }
mac-results-in =
    { $count ->
        [0] No results for “{ $words }” in { $folder }
        [one] { $count } result for “{ $words }” in { $folder }
       *[other] { $count } results for “{ $words }” in { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] still indexing the text of { $count } message
       *[other] still indexing the text of { $count } messages
    }
mac-folder-unread = { $folder }, { $count } unread
mac-import-messages = Import Messages
mac-save-messages = Save Messages
mac-save-attachments-menu = Save Attachments…
mac-files-not-saved =
    { $count ->
       *[other] { $failed } of the { $count } files could not be saved.
    }
mac-no-calendar-app = No calendar app is available on this Mac to open invitations (.ics files).
mac-unsubscribing = Unsubscribing from { $target }…

## The compose window

mac-bold = Bold
mac-italic = Italic
mac-underline = Underline
mac-bcc = Bcc
mac-command-click-to-open = ⌘-click to open
mac-saving-to-drafts = Saving to Drafts…
mac-dont-save = Don’t Save

## The reading pane

mac-files =
    { $count ->
        [one] { $count } file
       *[other] { $count } files
    }
mac-attendees =
    { $count ->
        [one] { $count } attendee
       *[other] { $count } attendees
    }

## Accounts

mac-next = Next
mac-name-placeholder = Ann Smith
mac-more-sign-in-options = More sign-in options…
mac-add-sign-in-app = Add a sign-in app…
mac-looking-up = Looking up the settings of { $domain }…
mac-add-button = Add…
mac-properties-button = Properties…
mac-signature-button = Signature…
mac-sign-in-apps-button = Sign-in Apps…

## AI agents

mac-forget-program = Remove this program and its agents’ activity history?
mac-forget-program-detail = The program’s permissions will be deleted. You will be asked for permission again the next time it connects.

## Sign-in apps

mac-checking-issuer = Checking { $issuer }…
mac-edit-button = Edit…
mac-use-for-new-accounts = Use { $name } for new accounts
mac-built-in = { $name } (built-in)

## Other windows

mac-new-folder-button = New Folder…
mac-edit-link = Edit Link…
