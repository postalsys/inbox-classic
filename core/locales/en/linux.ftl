# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = The search in { $place } covers subjects, senders, recipients, attachment names and message text. Check the spelling or try fewer words.
gtk-search-still-indexing = { $count ->
    [one] The text of 1 message is still being indexed. More results may appear soon.
   *[other] The text of { $count } messages is still being indexed. More results may appear soon.
}
gtk-search-results-everywhere = { $count ->
    [0] No results
    [one] 1 result
   *[other] { $count } results
} for “{ $words }” in all folders
gtk-search-results-in = { $count ->
    [0] No results
    [one] 1 result
   *[other] { $count } results
} for “{ $words }” in { $place }
gtk-search-indexing = { $count ->
    [one] still indexing the text of 1 message
   *[other] still indexing the text of { $count } messages
}
gtk-menu-rename = Rename...
gtk-import-one-question = Import the message { $file } into { $folder }?
gtk-files-not-saved = { $failed } of the { $total } files could not be saved.
gtk-unsubscribe-one-click =
    Leave this mailing list?

    Inbox Classic will send an unsubscribe request to { $target }. No web page will open and no e-mail will be sent.
gtk-unsubscribe-mail =
    Leave this mailing list?

    To unsubscribe, send an e-mail to { $target }. Inbox Classic will prepare it for you. Send the message to confirm.
gtk-unsubscribe-web =
    Leave this mailing list?

    The mailing list’s unsubscribe page will open in your browser ({ $target }).
gtk-unsubscribe-failed = Could not unsubscribe: { $problem }
gtk-toolbar-create-mail-menu = Compose from a specific account
gtk-toolbar-send-recv-menu = Send and receive mail for a specific account
gtk-main-menu = Main Menu
gtk-folder-list = Folder List
gtk-quit = Quit

## The Move and Copy window

gtk-new-folder-at-top-of = The new folder goes at the top of { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] No unread messages
    [one] 1 unread message
   *[other] { $count } unread messages
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = No messages are waiting to be sent.
gtk-outbox-row = To: { $to }  ·  Queued { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic keeps checking for new mail in the background. Use its icon in the top bar to open or quit the app.
gtk-sign-in-again-ask =
    Sign-in to { $account } was rejected or the session has expired.

    Sign in again in the browser?
gtk-default-app-not-installed = This copy of Inbox Classic was not installed, so the system does not list it as a mail app. Install it to choose it.
gtk-default-app-now = Inbox Classic is now your default mail app: e-mail links open a new message here.
gtk-default-app-failed = Inbox Classic could not be made the default mail app.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Date:
gtk-reader-files = Message attachments
gtk-pictures-blocked = Some pictures have been blocked to help prevent the sender from identifying your computer.
gtk-download-pictures = Download Pictures
gtk-save-attachments-menu = Save Attachments...

## The compose window

gtk-format-bold = Bold (Ctrl+B)
gtk-format-italic = Italic (Ctrl+I)
gtk-format-underline = Underline (Ctrl+U)
gtk-format-hyperlink = Hyperlink (Ctrl+K)
gtk-font = Font
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Save (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+click to open)

## Accounts

gtk-plain-warning =
    Without encryption, anyone who intercepts your network traffic can read your password and messages. Only use this connection with a server on your own computer or local network.

    Continue?
gtk-account-name-title = Account name
gtk-display-name-title = Display name
gtk-turned-off-why = The “{ $button }” option is disabled on this computer. { $reason }
gtk-turned-off-why-long =
    The “{ $button }” option is disabled on this computer.

    { $reason }
gtk-next = Next >
gtk-provider-sign-in = Sign in to { $address } on { $provider }’s website. Your password is not shared with Inbox Classic. You can also use an app password created in your account’s security settings.
gtk-provider-sign-in-apps = Sign in to { $address } on { $provider }’s website using one of your sign-in apps (More sign-in options). You can also use an app password created in your account’s security settings.
gtk-accounts-add = Add...
gtk-accounts-properties = Properties...
gtk-accounts-signature = Signature...
gtk-accounts-sign-in-apps = Sign-in Apps...

## Sign-in apps

gtk-app-server = { $kind } server
gtk-app-port = { $kind } port
gtk-app-security = { $kind } security
gtk-issuer-found =
    Sign-in page: { $page }
    Token endpoint: { $endpoint }
gtk-client-id = Client ID
gtk-client-secret = Client secret
gtk-scopes = Scopes
gtk-redirect-uri = Redirect URI
gtk-issuer-usable =
    The issuer can be used.

    { $found }
gtk-app-built-in = { $app } is built in. You can only change whether it is offered for new accounts. { $reason }
gtk-built-in = { $app } (built-in)
gtk-offered-for-new = Offered for new accounts
gtk-edit-button = Edit...
gtk-remove-app-ask = Remove the sign-in app { $app } and its saved client secret?
gtk-sign-in-apps-intro = Sign-in apps let accounts sign in through the browser. One that is turned off is not offered for new accounts; the accounts that already use it keep working.

## AI agents

gtk-agent-it-may = Allowed actions
gtk-agent-accounts = Allowed accounts
gtk-never-used = Never used
gtk-last-used = Last used { $date }
gtk-forget-program = Remove this program?
gtk-forget-program-detail = The program’s permissions and its agents’ activity history will be deleted. You will be asked for permission again the next time it connects.
gtk-no-agents-yet = No agent has asked to use your mail yet.
gtk-nothing-yet = Nothing yet.

## Preferences

gtk-preferences = Preferences
gtk-language = Language
gtk-language-subtitle = Language of the app and help
gtk-new-mail-group = New mail
gtk-notify-subtitle = A notification when new messages arrive while the window is in the background
gtk-restart-to-change = Inbox Classic restarts to change the language.
