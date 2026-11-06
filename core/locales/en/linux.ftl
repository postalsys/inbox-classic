# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-mail = Search mail
gtk-find-tip = Finds words in the subject, the people, the file names and the text of messages.
gtk-clear-search = Clear search
gtk-from-account = From { $account }
gtk-the-account = the account
gtk-column-folder = Folder
gtk-column-account = Account
gtk-search-looks-everywhere = The search looks at the subject, the people, the file names and the text of the messages in every folder. Check the spelling, or try fewer words.
gtk-search-looks-in = The search looks at the subject, the people, the file names and the text of the messages in { $place }. Check the spelling, or try fewer words.
gtk-search-still-indexing = { $count ->
    [one] The text of 1 message is still being indexed, so more may be found soon.
   *[other] The text of { $count } messages are still being indexed, so more may be found soon.
}
gtk-search-no-match = No messages match “{ $words }”.
gtk-list-empty = There are no items in this view.
gtk-list-choose-folder = Choose a folder to see its messages.
gtk-all-inboxes = All Inboxes
gtk-all-folders = All folders
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
gtk-toolbar-junk = Junk
gtk-toolbar-not-junk = Not Junk
gtk-menu-rename = Rename...
gtk-menu-delete = Delete
gtk-new-folder-in-selected = The new folder goes in the selected folder.
gtk-new-folder-at-top = The new folder goes at the top of the account.
gtk-new-folder-title = New Folder
gtk-rename-folder-intro = The new name of the folder { $folder }.
gtk-rename-folder-title = Rename Folder
gtk-delete-folder-question = Delete the folder “{ $folder }” with its messages and the folders in it? It is deleted on the server too.
gtk-not-downloaded = The message is not downloaded yet.
gtk-mail-messages = Mail messages
gtk-save-message-as = Save Message As
gtk-message-not-saved = The message could not be saved.
gtk-save-messages-in = Save Messages In
gtk-select-message-first = Select a message first.
gtk-properties = Properties
gtk-properties-of = { $subject } Properties
gtk-internet-headers = Internet headers for this message:
gtk-menu-open = Open
gtk-menu-flag = Flag
gtk-menu-view-source = View Source
gtk-import-choose-folder = Choose the folder to put the messages in first.
gtk-import-one-question = Put the message { $file } into the folder { $folder }?
gtk-attachment-not-read = The attachment could not be read.
gtk-save-attachment-as = Save Attachment As
gtk-attachment-not-saved = The attachment could not be saved.
gtk-save-attachments = Save Attachments
gtk-files-not-saved = { $failed } of the { $total } files could not be saved.
gtk-invitation-not-read = The invitation could not be read.
gtk-no-calendar-program = No calendar program on this computer opens invitations (.ics files).
gtk-cancel = Cancel
gtk-ok = OK
gtk-unsubscribe = Unsubscribe
gtk-unsubscribe-one-click =
    Leave this mailing list?

    Inbox Classic asks { $target } to stop sending it to you. No page opens and no message is sent.
gtk-unsubscribing = Unsubscribing from { $target }...
gtk-can-not-unsubscribe = This message can not unsubscribe you.
gtk-unsubscribe-mail =
    Leave this mailing list?

    The list wants a message to { $target }. Inbox Classic writes it for you; send it to unsubscribe.
gtk-unsubscribe-web =
    Leave this mailing list?

    The list's page for it opens in your browser ({ $target }).
gtk-unsubscribed = Unsubscribed. The list says it will stop sending this mail.
gtk-unsubscribe-failed = Could not unsubscribe: { $problem }
gtk-toolbar-create-mail = Create Mail
gtk-toolbar-create-mail-menu = A message from one account
gtk-toolbar-send-recv = Send/Recv
gtk-toolbar-send-recv-menu = Send and receive one account
gtk-toolbar-reply = Reply
gtk-toolbar-reply-all = Reply All
gtk-toolbar-forward = Forward
gtk-toolbar-print = Print
gtk-toolbar-delete = Delete
gtk-toolbar-mark-read = Mark Read
gtk-toolbar-mark-unread = Mark Unread
gtk-main-menu = Main Menu
gtk-quit = Quit
gtk-clear-flag = Clear Flag

## The Move and Copy window

gtk-button-move = Move
gtk-button-copy = Copy
gtk-find-folder = Find a folder
gtk-new-folder-in = The new folder goes in { $folder }.
gtk-new-folder-at-top-of = The new folder goes at the top of { $account }.

## The message list

gtk-column-from = From
gtk-column-subject = Subject
gtk-column-received = Received
gtk-column-size = Size

## Help

gtk-help-title = Inbox Classic Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] No unread messages
    [one] 1 unread message
   *[other] { $count } unread messages
}
gtk-done = Done

## The compose window's link menu

gtk-open-link = Open Link
gtk-edit-link = Edit Link...
gtk-remove-link = Remove Link

## The Outbox

gtk-no-subject = (no subject)
gtk-outbox-title = Outbox
gtk-outbox-empty = Nothing waits to be sent.
gtk-outbox-send-all = Send All Now
gtk-outbox-delete = Delete
gtk-outbox-delete-ask = Delete this message without sending it?
gtk-outbox-waiting = Waiting
gtk-outbox-not-sent = Not sent: { $reason }
gtk-outbox-agent = Sent by an AI agent; goes at { $time }
gtk-outbox-row = To: { $to }  ·  Queued { $queued }  ·  { $status }

## The app

gtk-store-not-opened = The mail store could not be opened.
gtk-store-or-cert-not-opened = The mail store or the certificate file could not be opened.
gtk-checking = Checking for new messages on { $account }...
gtk-sent-at = Sent { $subject } at { $time }
gtk-draft-saved = Message saved in Drafts.
gtk-draft-not-saved = The message was not saved in Drafts: { $reason }
gtk-newest-from = The newest from { $sender }: { $subject }
gtk-new-messages = { $count } new messages
gtk-outbox-waits = { $subject } waits in the Outbox
gtk-outbox-sending = Sending { $subject }...
gtk-outbox-count = { $count ->
    [one] 1 message in the Outbox
   *[other] { $count } messages in the Outbox
}
gtk-still-running = Inbox Classic is still running
gtk-still-running-detail = It keeps checking for new mail. Its icon in the top bar opens it again, or quits it.
gtk-add-account-first = Add a mail account first.
gtk-add-account-first-link = Add a mail account first, then click the e-mail link again.
gtk-quoted = “{ $subject }”
gtk-sign-in-again-ask =
    The sign-in of { $account } was refused or ran out.

    Sign in again in the browser?
gtk-sign-in-again-failed = Signing in again did not work: { $reason }
gtk-default-app-not-installed = This copy of Inbox Classic was not installed, so the system does not list it as a mail app. Install it to choose it.
gtk-default-app-is = Inbox Classic is your default mail app: e-mail links open a new message here.
gtk-default-app-now = Inbox Classic is now your default mail app: e-mail links open a new message here.
gtk-default-app-failed = Inbox Classic could not be made the default mail app.
gtk-about-core = Core { $version }

## Buttons and words used in many windows

gtk-yes = Yes
gtk-no = No
gtk-folder-name = Folder name:
gtk-all-files = All files

## The reading pane

gtk-reader-from = From:
gtk-reader-to = To:
gtk-reader-date = Date:
gtk-reader-files = The files of the message
gtk-open-in-calendar = Open in Calendar
gtk-pictures-blocked = Some pictures have been blocked to help prevent the sender from identifying your computer.
gtk-download-pictures = Download Pictures
gtk-try-again = Try Again
gtk-message-not-shown = The message could not be shown.
gtk-save-attachments-menu = Save Attachments...
gtk-no-title = (no title)
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
gtk-from-to = { $start } to { $end }
gtk-day-and-time = { $day }, { $time }
gtk-senders-time = { $when } (the sender's time)

## The compose window

gtk-format-bold = Bold (Ctrl+B)
gtk-format-italic = Italic (Ctrl+I)
gtk-format-underline = Underline (Ctrl+U)
gtk-format-font-color = Font Color
gtk-format-numbered-list = Numbered List
gtk-format-bulleted-list = Bulleted List
gtk-format-decrease-indent = Decrease Indent
gtk-format-increase-indent = Increase Indent
gtk-format-align-left = Align Left
gtk-format-center = Center
gtk-format-align-right = Align Right
gtk-format-hyperlink = Hyperlink (Ctrl+K)
gtk-format-insert-horizontal-line = Insert Horizontal Line
gtk-format-insert-picture = Insert Picture
gtk-font = Font
gtk-font-size = Size
gtk-link-invalid = Type a web address (https://...) or an e-mail link (mailto:...).
gtk-edit-hyperlink = Edit Hyperlink
gtk-edit-hyperlink-intro = Where the link goes. Empty the address to remove the link and keep its text.
gtk-hyperlink = Hyperlink
gtk-hyperlink-intro = The address the selected text links to.
gtk-link-address = Address:
gtk-pictures = Pictures
gtk-insert-picture = Insert Picture
gtk-not-a-picture = This file is not a PNG, JPEG or GIF picture, or it is larger than 10 MB.
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-compose-from = From:
gtk-compose-to = To:
gtk-compose-cc = Cc:
gtk-compose-bcc = Bcc:
gtk-compose-subject = Subject:
gtk-compose-attach = Attach:
gtk-send = Send
gtk-save-tip = Save (Ctrl+S)
gtk-attach-tip = Attach
gtk-new-message = New Message
gtk-remove = Remove
gtk-link-status = { $link }    (Ctrl+click to open)
gtk-insert-attachment = Insert Attachment
gtk-saving-draft = Saving to Drafts...
gtk-save-changes = Do you want to save changes to this message in Drafts?
gtk-not-saved-in-drafts = Not saved in Drafts: { $reason }
gtk-saved-in-drafts-at = Saved in Drafts at { $time }
gtk-signature-hint = Added to new messages, replies and forwards from this account.
gtk-signature-of = Signature - { $account }
gtk-signature = Signature
gtk-signature-not-saved = The signature could not be saved.

## Accounts

gtk-add-mail-account = Add Mail Account
gtk-account-not-saved = The account could not be saved.
gtk-security-none = None (unencrypted)
gtk-field-required = { $field } is required.
gtk-address-not-valid = The e-mail address is not valid.
gtk-ports-are-numbers = Ports are numbers from 1 to 65535.
gtk-display-name = Display name:
gtk-email-address = E-mail address:
gtk-user-name = User name:
gtk-password = Password:
gtk-imap-server = Incoming (IMAP) server:
gtk-imap-port = IMAP port:
gtk-imap-security = IMAP security:
gtk-smtp-server = Outgoing (SMTP) server:
gtk-smtp-port = SMTP port:
gtk-smtp-security = SMTP security:
gtk-plain-warning =
    Without encryption your password and mail travel the network readable by anyone on the way. Use this only for a server on your own computer or network.

    Continue?
gtk-sign-in-with = Sign in with { $provider }
gtk-the-provider = the provider
gtk-more-sign-in = More sign-in options...
gtk-display-name-title = Display name
gtk-email-address-title = E-mail address
gtk-other-account-intro = Any other e-mail account: your name as others see it and your e-mail address. Its servers are looked up next.
gtk-type-address = Type your e-mail address, name@example.com.
gtk-turned-off-why = { $button } is turned off on this computer. { $reason }
gtk-turned-off-why-long =
    { $button } is turned off on this computer.

    { $reason }
gtk-turned-off = Turned off on this computer.
gtk-why = Why?
gtk-add-sign-in-app = Add a sign-in app...
gtk-browser-sign-in-not-started = Signing in through the browser could not start.
gtk-sign-in-in-browser = Sign in to { $account } in the browser window that opened, then come back here.
gtk-sign-in-in-browser-yours = Sign in to your account in the browser window that opened, then come back here.
gtk-signing-in-failed = Signing in did not work: { $reason }
gtk-looking-up = Looking up the settings of { $domain }...
gtk-found-none = Enter the account details your e-mail provider gave you.
gtk-found-guess = No settings were found for this address: these are the usual names, check them with your provider.
gtk-found-mx = Your mail is handled by a provider Inbox Classic knows; these are its servers.
gtk-found-srv = These settings were found in the DNS records of your domain.
gtk-found-autodiscover = These settings were found by Microsoft Autodiscover (Exchange).
gtk-found-other = These settings were found for this address.
gtk-found-change = Change them if your provider gave you others.
gtk-app-password-needed = { $provider } does not take your normal password in mail programs. Create an app password in your { $provider } account and type it in the Password field of the next form.
gtk-open-instructions = Open { $provider }'s instructions in your browser?
gtk-start-intro = Gmail, Google Workspace, Outlook.com and Microsoft 365: sign in on Google's or Microsoft's own page. Your password is typed there, never into Inbox Classic.
gtk-start-intro-apps = Sign in through the browser with one of your sign-in apps (More sign-in options), or add any e-mail account with your name and address below.
gtk-next = Next >
gtk-provider-sign-in = { $address } signs in on { $provider }'s own page, without giving Inbox Classic your password. Or use an app password made in your account's security settings.
gtk-provider-sign-in-apps = { $address } can sign in on { $provider }'s own page with one of your sign-in apps (More sign-in options). Or use an app password made in your account's security settings.
gtk-use-app-password = Use App Password
gtk-finish = Finish
gtk-enter-password = Enter the password of { $account }.
gtk-logon = Logon
gtk-signs-in-with = Signs in with: { $app }. It signs in through the browser and uses the servers of its sign-in.
gtk-keep-password = Leave the password empty to keep the one you have.
gtk-browser-sign-in-server = { $server } (browser sign-in)
gtk-accounts-add = Add...
gtk-accounts-properties = Properties...
gtk-accounts-signature = Signature...
gtk-accounts-sign-in-apps = Sign-in Apps...
gtk-accounts-title = Accounts
gtk-remove-account = Remove Account
gtk-remove-account-ask = Remove this account from Inbox Classic? Its mail stays on the server; the copy on this computer and the saved password are removed.

## Sign-in apps

gtk-sign-in-app = Sign-in App
gtk-remove-sign-in-app = Remove Sign-in App
gtk-check = Check
gtk-app-server = { $kind } server
gtk-app-port = { $kind } port
gtk-app-security = { $kind } security
gtk-preset-name = { $provider } sign-in app
gtk-checking-issuer = Checking { $issuer }...
gtk-issuer-found =
    Sign-in page: { $page }
    Token endpoint: { $endpoint }
gtk-app-editor-intro = An OAuth client you registered with your provider, for accounts that sign in through the browser. Fill it in for a provider, then add the client ID (and secret, if the provider gave one).
gtk-fill-in-for = Fill in for:
gtk-app-name = Name
gtk-issuer = Issuer
gtk-client-id = Client ID
gtk-client-secret = Client secret
gtk-secret-saved = A secret is saved; type another to replace it, or remove it
gtk-scopes = Scopes
gtk-register-it = Register it with your provider
gtk-redirect-uri = Redirect URI
gtk-copy-button = Copy
gtk-add-sign-in-app-title = Add Sign-in App
gtk-issuer-usable =
    The issuer can be used.

    { $found }
gtk-issuer-not-usable = The issuer can not be used: { $reason }
gtk-app-not-saved = The sign-in app could not be saved: { $reason }
gtk-app-built-in = { $app } is built in: only whether it is used for new accounts can change. { $reason }
gtk-client-with-secret = Client ID: { $client }, with a client secret.
gtk-client-public = Client ID: { $client }, a public client (no secret).
gtk-no-accounts = No accounts
gtk-built-in = { $app } (built-in)
gtk-offered-for-new = Offered for new accounts
gtk-edit-button = Edit...
gtk-sign-in-apps-title = Sign-in Apps
gtk-remove-app-ask = Remove the sign-in app { $app } and its saved client secret?
gtk-app-not-removed = The sign-in app was not removed: { $reason }
gtk-sign-in-apps-intro = Sign-in apps let accounts sign in through the browser. One that is turned off is not offered for new accounts; the accounts that already use it keep working.

## AI agents

gtk-agent-program = Program: { $path }
gtk-agent-it-may = It may
gtk-agent-accounts = Accounts it may use
gtk-dont-allow = Don’t Allow
gtk-allow = Allow
gtk-dont-send = Don’t Send
gtk-edit-first = Edit First
gtk-new-address = New address
gtk-never-used = Never used
gtk-last-used = Last used { $date }
gtk-turn-away = Turn Away
gtk-forget-program = Forget this program?
gtk-forget-program-detail = It is asked about again the next time it connects, and what its agents did is forgotten.
gtk-ai-agents = AI Agents
gtk-clear-agent-log = Clear the list of what agents did?
gtk-clear-agent-log-detail = What they did stays done.
gtk-let-agents-connect = Let AI agents connect to Inbox Classic
gtk-no-agents-yet = No agent has asked to use your mail yet.
gtk-nothing-yet = Nothing yet.
gtk-change-button = Change…
gtk-undo-button = Undo
gtk-clear-button = Clear
gtk-how-to-connect = How to Connect an Agent…
gtk-agent-programs = Programs whose agents asked to use your mail
gtk-what-agents-did = What agents did
gtk-connect-agent = Connect an AI Agent
gtk-connect-agent-intro = Add this to the MCP servers of your agent (Claude Desktop: Settings > Developer > Edit Config):

## Preferences

gtk-preferences = Preferences
gtk-language = Language
gtk-language-subtitle = The words of the windows and the help
gtk-system-default = System default ({ $language })
gtk-new-mail-group = New mail
gtk-notify-subtitle = A notification when new messages arrive while the window is in the background
gtk-restart-to-change = Inbox Classic restarts to change the language.
gtk-restart-now = Restart Now
gtk-restart-later = Later
