# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = The search looks at the subject, the people, the file names and the text of the messages in { $place }. Check the spelling, or try fewer words.
gtk-search-still-indexing = { $count ->
    [one] The text of 1 message is still being indexed, so more may be found soon.
   *[other] The text of { $count } messages are still being indexed, so more may be found soon.
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
gtk-import-one-question = Put the message { $file } into the folder { $folder }?
gtk-files-not-saved = { $failed } of the { $total } files could not be saved.
gtk-unsubscribe-one-click =
    Leave this mailing list?

    Inbox Classic asks { $target } to stop sending it to you. No page opens and no message is sent.
gtk-unsubscribe-mail =
    Leave this mailing list?

    The list wants a message to { $target }. Inbox Classic writes it for you; send it to unsubscribe.
gtk-unsubscribe-web =
    Leave this mailing list?

    The list's page for it opens in your browser ({ $target }).
gtk-unsubscribe-failed = Could not unsubscribe: { $problem }
gtk-toolbar-create-mail-menu = A message from one account
gtk-toolbar-send-recv-menu = Send and receive one account
gtk-main-menu = Main Menu
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

gtk-outbox-empty = Nothing waits to be sent.
gtk-outbox-row = To: { $to }  ·  Queued { $queued }  ·  { $status }

## The app

gtk-new-messages = { $count } new messages
gtk-still-running-detail = It keeps checking for new mail. Its icon in the top bar opens it again, or quits it.
gtk-sign-in-again-ask =
    The sign-in of { $account } was refused or ran out.

    Sign in again in the browser?
gtk-default-app-not-installed = This copy of Inbox Classic was not installed, so the system does not list it as a mail app. Install it to choose it.
gtk-default-app-now = Inbox Classic is now your default mail app: e-mail links open a new message here.
gtk-default-app-failed = Inbox Classic could not be made the default mail app.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Date:
gtk-reader-files = The files of the message
gtk-pictures-blocked = Some pictures have been blocked to help prevent the sender from identifying your computer.
gtk-download-pictures = Download Pictures
gtk-save-attachments-menu = Save Attachments...
gtk-invitation = { $kind ->
    [update] Updated invitation: { $summary }
    [cancel] Canceled: { $summary }
    [reply] Answer to an invitation: { $summary }
   *[request] Invitation: { $summary }
}
gtk-organizer = Organizer: { $organizer }
gtk-attendees = { $count ->
    [one] 1 attendee
   *[other] { $count } attendees
}
gtk-day-and-time = { $day }, { $time }

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
    Without encryption your password and mail travel the network readable by anyone on the way. Use this only for a server on your own computer or network.

    Continue?
gtk-display-name-title = Display name
gtk-turned-off-why = { $button } is turned off on this computer. { $reason }
gtk-turned-off-why-long =
    { $button } is turned off on this computer.

    { $reason }
gtk-next = Next >
gtk-provider-sign-in = { $address } signs in on { $provider }'s own page, without giving Inbox Classic your password. Or use an app password made in your account's security settings.
gtk-provider-sign-in-apps = { $address } can sign in on { $provider }'s own page with one of your sign-in apps (More sign-in options). Or use an app password made in your account's security settings.
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
gtk-app-built-in = { $app } is built in: only whether it is used for new accounts can change. { $reason }
gtk-built-in = { $app } (built-in)
gtk-offered-for-new = Offered for new accounts
gtk-edit-button = Edit...
gtk-remove-app-ask = Remove the sign-in app { $app } and its saved client secret?
gtk-sign-in-apps-intro = Sign-in apps let accounts sign in through the browser. One that is turned off is not offered for new accounts; the accounts that already use it keep working.

## AI agents

gtk-agent-it-may = It may
gtk-agent-accounts = Accounts it may use
gtk-never-used = Never used
gtk-last-used = Last used { $date }
gtk-forget-program = Forget this program?
gtk-forget-program-detail = It is asked about again the next time it connects, and what its agents did is forgotten.
gtk-no-agents-yet = No agent has asked to use your mail yet.
gtk-nothing-yet = Nothing yet.

## Preferences

gtk-preferences = Preferences
gtk-language = Language
gtk-language-subtitle = The words of the windows and the help
gtk-new-mail-group = New mail
gtk-notify-subtitle = A notification when new messages arrive while the window is in the background
gtk-restart-to-change = Inbox Classic restarts to change the language.
