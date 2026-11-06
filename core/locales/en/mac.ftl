# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.

## The app and its menus

mac-store-not-opened = The mail store could not be opened.
mac-store-or-certificate-not-opened = The mail store or the certificate file could not be opened.
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
mac-copy = Copy
mac-paste = Paste
mac-menu-window = Window
mac-minimize = Minimize
mac-zoom = Zoom
mac-help-title = Inbox Classic Help
mac-no-updates = This copy of Inbox Classic does not update itself. Get the latest version from inboxclassic.com.
mac-flag = Flag
mac-clear-flag = Clear Flag

## Settings

mac-settings-title = Settings
mac-language-label = Language:
mac-system-default = System default ({ $language })
mac-restart-hint = Inbox Classic starts again to change the language.
mac-notify-new-mail = Notify me when new mail arrives
mac-restart-question = Start Inbox Classic again now to change the language?
mac-restart-now = Restart Now
mac-restart-later = Later

## Dialogs

mac-ok = OK
mac-cancel = Cancel
mac-yes = Yes
mac-no = No
mac-folder-name = Folder name:
mac-save-attachment-as = Save Attachment As
mac-choose = Choose
mac-messages-not-changed = The messages could not be changed.

## The main window

mac-still-running = Inbox Classic is still running
mac-still-running-detail = It keeps checking for new mail. Click its icon in the Dock to open it again.
mac-no-subject = (no subject)
mac-quoted = “{ $subject }”
mac-outbox-waiting =
    { $count ->
        [one] { $count } message in the Outbox
       *[other] { $count } messages in the Outbox
    }
mac-outbox-waits = { $subject } waits in the Outbox
mac-sending = Sending { $subject }…
mac-checking = Checking for new messages on { $account }…
mac-done = Done
mac-sent-at = Sent { $subject } at { $time }
mac-draft-saved = Message saved in Drafts.
mac-draft-not-saved = The message was not saved in Drafts: { $reason }
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } new message
       *[other] { $count } new messages
    }
mac-newest-from = The newest from { $from }: { $subject }
mac-sign-in-refused = The sign-in of { $account } was refused or ran out.
mac-sign-in-again = Sign in again in the browser?
mac-sign-in-failed = Signing in again did not work: { $reason }
mac-unknown-reason = unknown reason
mac-core-version = Core { $version }
mac-add-account-first = Add a mail account first.
mac-add-account-first-link = Add a mail account first, then click the e-mail link again.
mac-select-message-first = Select a message first.
mac-not-bundle = This copy of Inbox Classic is not an app bundle, so it can not be the default mail app.
mac-is-default = Inbox Classic is your default mail app: e-mail links open a new message here.
mac-not-made-default = Inbox Classic was not made the default mail app: { $reason }
mac-tool-create-mail = Create Mail
mac-tool-reply = Reply
mac-tool-reply-all = Reply All
mac-tool-forward = Forward
mac-tool-print = Print
mac-tool-delete = Delete
mac-tool-junk = Junk
mac-tool-not-junk = Not Junk
mac-tool-sync = Send/Recv
mac-tool-mark-read = Mark Read
mac-tool-mark-unread = Mark Unread
mac-tool-search = Search
mac-search-mail = Search mail
mac-find-tip = Finds words in the subject, the people, the file names and the text of messages.
mac-from-account = From { $account }

## The folders and the message list

mac-clear-search = Clear search
mac-all-inboxes = All Inboxes
mac-the-account = the account
mac-all-folders = All folders
mac-column-received = Received
mac-column-size = Size
mac-column-folder = Folder
mac-column-account = Account
mac-no-match = No messages match “{ $words }”.
mac-search-looks-everywhere = The search looks at the subject, the people, the file names and the text of the messages in every folder. Check the spelling, or try fewer words.
mac-search-looks-in = The search looks at the subject, the people, the file names and the text of the messages in { $folder }. Check the spelling, or try fewer words.
mac-still-indexing-more =
    { $count ->
        [one] The text of { $count } message is still being indexed, so more may be found soon.
       *[other] The text of { $count } messages is still being indexed, so more may be found soon.
    }
mac-no-items = There are no items in this view.
mac-choose-folder = Choose a folder to see its messages.
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
mac-message-not-shown = The message could not be shown.
mac-delete = Delete
mac-move-button = Move
mac-copy-button = Copy
mac-new-folder = New Folder
mac-new-folder-in-selected = The new folder goes in the selected folder.
mac-new-folder-at-top = The new folder goes at the top of the account.
mac-folder-not-created = The folder could not be created.
mac-rename-folder = Rename Folder
mac-rename-folder-intro = The new name of the folder { $folder }.
mac-folder-not-renamed = The folder could not be renamed.
mac-delete-folder-question = Delete the folder “{ $folder }” with its messages and the folders in it? It is deleted on the server too.
mac-folder-not-deleted = The folder could not be deleted.
mac-not-downloaded = The message is not downloaded yet.
mac-save-message-as = Save Message As
mac-message-not-saved = The message could not be saved.
mac-properties = Properties
mac-properties-of = { $subject } Properties
mac-internet-headers = Internet headers for this message:
mac-close = Close
mac-open = Open
mac-view-source = View Source
mac-import-messages = Import Messages
mac-import-choose-folder = Choose the folder to put the messages in first.
mac-save-messages = Save Messages
mac-save-attachments-menu = Save Attachments…
mac-save-attachments = Save Attachments
mac-attachment-not-read = The attachment could not be read.
mac-attachment-not-saved = The attachment could not be saved.
mac-files-not-saved =
    { $count ->
       *[other] { $failed } of the { $count } files could not be saved.
    }
mac-invitation-not-read = The invitation could not be read.
mac-no-calendar-app = No calendar app on this Mac opens invitations (.ics files).
mac-leave-list = Leave this mailing list?
mac-unsubscribe = Unsubscribe
mac-unsubscribe-one-click = Inbox Classic asks { $target } to stop sending it to you. No page opens and no message is sent.
mac-unsubscribe-mail = The list wants a message to { $target }. Inbox Classic writes it for you; send it to unsubscribe.
mac-unsubscribe-web = The list's page for it opens in your browser ({ $target }).
mac-unsubscribing = Unsubscribing from { $target }…
mac-can-not-unsubscribe = This message can not unsubscribe you.
mac-unsubscribed = Unsubscribed. The list says it will stop sending this mail.
mac-not-unsubscribed = Could not unsubscribe: { $reason }

## The compose window

mac-bold = Bold
mac-italic = Italic
mac-underline = Underline
mac-numbered-list = Numbered List
mac-bulleted-list = Bulleted List
mac-align-left = Align Left
mac-center = Center
mac-align-right = Align Right
mac-font-color = Font Color
mac-decrease-indent = Decrease Indent
mac-increase-indent = Increase Indent
mac-hyperlink = Hyperlink
mac-edit-hyperlink = Edit Hyperlink
mac-hyperlink-intro = The address the selected text links to.
mac-edit-hyperlink-intro = Where the link goes. Empty the address to remove the link and keep its text.
mac-link-address = Address:
mac-link-invalid = Type a web address (https://...) or an e-mail link (mailto:...).
mac-horizontal-line = Insert Horizontal Line
mac-insert-picture = Insert Picture
mac-not-a-picture = This file is not a PNG, JPEG or GIF picture, or it is larger than 10 MB.
mac-bcc = Bcc
mac-new-message = New Message
mac-field-from = From:
mac-field-to = To:
mac-field-cc = Cc:
mac-field-bcc = Bcc:
mac-field-subject = Subject:
mac-field-attach = Attach:
mac-command-click-to-open = ⌘-click to open
mac-remove = Remove
mac-insert-attachment = Insert Attachment
mac-message-not-sent = The message could not be sent.
mac-saving-to-drafts = Saving to Drafts…
mac-save-changes-question = Do you want to save changes to this message in Drafts?
mac-save = Save
mac-dont-save = Don’t Save
mac-saved-in-drafts-at = Saved in Drafts at { $time }
mac-not-saved-in-drafts = Not saved in Drafts: { $reason }
mac-send = Send
mac-attach = Attach
mac-signature = Signature
mac-signature-title = Signature - { $account }
mac-signature-hint = Added to new messages, replies and forwards from this account.
mac-signature-not-saved = The signature could not be saved.

## The reading pane

mac-open-in-calendar = Open in Calendar
mac-try-again = Try Again
mac-pictures-blocked = Some pictures have been blocked to help prevent the sender from identifying your computer. Click here to download pictures.
mac-files =
    { $count ->
        [one] { $count } file
       *[other] { $count } files
    }
mac-invitation = Invitation: { $title }
mac-invitation-updated = Updated invitation: { $title }
mac-invitation-canceled = Canceled: { $title }
mac-invitation-answer = Answer to an invitation: { $title }
mac-no-title = (no title)
mac-organizer = Organizer: { $name }
mac-attendees =
    { $count ->
        [one] { $count } attendee
       *[other] { $count } attendees
    }
mac-from-to = { $start } to { $end }
mac-senders-time = { $when } (the sender's time)

## Accounts

mac-security-none = None (unencrypted)
mac-field-required = { $field } is required.
mac-email-invalid = The e-mail address is not valid.
mac-ports-invalid = Ports are numbers from 1 to 65535.
mac-plain-warning = Without encryption your password and mail travel the network readable by anyone on the way. Use this only for a server on your own computer or network.
mac-continue-question = Continue?
mac-display-name = Display name:
mac-email-address = E-mail address:
mac-user-name = User name:
mac-password = Password:
mac-imap-server = Incoming (IMAP) server:
mac-imap-port = IMAP port:
mac-imap-security = IMAP security:
mac-smtp-server = Outgoing (SMTP) server:
mac-smtp-port = SMTP port:
mac-smtp-security = SMTP security:
mac-sign-in-not-started = Signing in through the browser could not start.
mac-sign-in-waiting = Sign in to { $account } in the browser window that opened, then come back here.
mac-sign-in-waiting-any = Sign in to your account in the browser window that opened, then come back here.
mac-add-mail-account = Add Mail Account
mac-sign-in-did-not-work = Signing in did not work: { $reason }
mac-sign-in-with = Sign in with { $provider }
mac-next = Next
mac-name-placeholder = Ann Smith
mac-more-sign-in-options = More sign-in options…
mac-any-other-account = Any other e-mail account: your name as others see it and your e-mail address. Its servers are looked up next.
mac-turned-off-named = { $name } is turned off on this computer.
mac-turned-off = Turned off on this computer.
mac-why = Why?
mac-add-sign-in-app = Add a sign-in app…
mac-type-email = Type your e-mail address, name@example.com.
mac-found-none = Enter the account details your e-mail provider gave you.
mac-found-change = Change them if your provider gave you others.
mac-found-guess = No settings were found for this address: these are the usual names, check them with your provider.
mac-found-mx = Your mail is handled by a provider Inbox Classic knows; these are its servers.
mac-found-srv = These settings were found in the DNS records of your domain.
mac-found-autodiscover = These settings were found by Microsoft Autodiscover (Exchange).
mac-found-other = These settings were found for this address.
mac-app-password-needed = { $provider } does not take your normal password in mail programs. Create an app password in your { $provider } account and type it in the Password field of the next form.
mac-open-instructions = Open { $provider }'s instructions in your browser?
mac-account-not-saved = The account could not be saved.
mac-start-intro = Gmail, Google Workspace, Outlook.com and Microsoft 365: sign in on Google's or Microsoft's own page. Your password is typed there, never into Inbox Classic.
mac-start-intro-apps = Sign in through the browser with one of your sign-in apps (More sign-in options), or add any e-mail account with your name and address below.
mac-looking-up = Looking up the settings of { $domain }…
mac-use-app-password = Use App Password
mac-the-provider = the provider
mac-signs-in-at = { $email } signs in on { $provider }'s own page, without giving Inbox Classic your password. Or use an app password made in your account's security settings.
mac-can-sign-in-at = { $email } can sign in on { $provider }'s own page with one of your sign-in apps (More sign-in options). Or use an app password made in your account's security settings.
mac-finish = Finish
mac-logon = Logon
mac-enter-password = Enter the password of { $account }.
mac-signs-in-with = Signs in with: { $app }. It signs in through the browser and uses the servers of its sign-in.
mac-keep-password = Leave the password empty to keep the one you have.
mac-accounts = Accounts
mac-column-email = E-mail address
mac-column-incoming = Incoming server
mac-add-button = Add…
mac-properties-button = Properties…
mac-signature-button = Signature…
mac-sign-in-apps-button = Sign-in Apps…
mac-browser-sign-in = { $server } (browser sign-in)
mac-remove-account = Remove Account
mac-remove-account-question = Remove this account from Inbox Classic? Its mail stays on the server; the copy on this computer and the saved password are removed.

## AI agents

mac-ai-agent = AI Agent
mac-allow = Allow
mac-dont-allow = Don’t Allow
mac-program-path = Program: { $path }
mac-it-may = It may:
mac-accounts-it-may-use = Accounts it may use:
mac-new-address = New address
mac-send-message-question = Send Message?
mac-edit-first = Edit First
mac-dont-send = Don’t Send
mac-let-agents-connect = Let AI agents connect to Inbox Classic
mac-change-button = Change…
mac-undo-button = Undo
mac-clear = Clear
mac-ai-agents = AI Agents
mac-column-program = Program
mac-column-may = May
mac-column-last-used = Last used
mac-column-when = When
mac-column-what = What
mac-how-to-connect = How to Connect an Agent…
mac-agent-programs = Programs whose agents asked to use your mail
mac-agent-log = What agents did
mac-never = Never
mac-ai-agent-access = AI Agent Access
mac-turn-away = Turn Away
mac-forget-program = Forget this program and what its agents did?
mac-forget-program-detail = It is asked about again the next time it connects.
mac-clear-log = Clear the list of what agents did?
mac-clear-log-detail = What they did stays done.
mac-connect-agent = Connect an AI Agent
mac-connect-agent-intro = Add this to the MCP servers of your agent (Claude Desktop: Settings > Developer > Edit Config):

## Sign-in apps

mac-secret-saved = A secret is saved; type another to replace it, or remove it
mac-add-sign-in-app-title = Add Sign-in App
mac-sign-in-app = Sign-in App
mac-sign-in-apps = Sign-in Apps
mac-sign-in-app-intro = An OAuth client you registered with your provider, for accounts that sign in through the browser. Fill it in for a provider, then add the client ID (and secret, if the provider gave one).
mac-check = Check
mac-fill-in-for = Fill in for:
mac-app-name = Name:
mac-issuer = Issuer:
mac-client-id = Client ID:
mac-client-secret = Client secret:
mac-scopes = Scopes:
mac-app-imap-server = IMAP server:
mac-app-smtp-server = SMTP server:
mac-register-it = Register it with your provider
mac-redirect-uri = Redirect URI:
mac-preset-app-name = { $provider } sign-in app
mac-issuer-not-checked = the issuer can not be checked
mac-checking-issuer = Checking { $issuer }…
mac-issuer-usable = The issuer can be used.
mac-issuer-not-usable = The issuer can not be used: { $reason }
mac-sign-in-app-not-saved = The sign-in app could not be saved: { $reason }
mac-edit-button = Edit…
mac-column-name = Name
mac-column-issuer = Issuer
mac-column-used-by = Used by
mac-sign-in-apps-intro = Sign-in apps let accounts sign in through the browser. One that is not checked is not offered for new accounts; the accounts that already use it keep working.
mac-use-for-new-accounts = Use { $name } for new accounts
mac-built-in = { $name } (built-in)
mac-no-accounts = No accounts
mac-built-in-note = { $name } is built in: only whether it is used for new accounts can change.
mac-client-with-secret = Client ID: { $client }, with a client secret.
mac-client-public = Client ID: { $client }, a public client (no secret).
mac-remove-sign-in-app = Remove Sign-in App
mac-remove-sign-in-app-question = Remove the sign-in app { $name } and its saved client secret?
mac-sign-in-app-not-removed = The sign-in app was not removed: { $reason }

## Other windows

mac-find-folder = Find a folder
mac-new-folder-button = New Folder…
mac-new-folder-in = The new folder goes in { $folder }.
mac-send-all-now = Send All Now
mac-outbox = Outbox
mac-column-queued = Queued
mac-column-status = Status
mac-not-sent = Not sent: { $reason }
mac-agent-goes-at = Sent by an AI agent; goes at { $time }
mac-waiting = Waiting
mac-delete-unsent = Delete this message without sending it?
mac-open-link = Open Link
mac-edit-link = Edit Link…
mac-remove-link = Remove Link
mac-help-missing = The help is missing from this copy of Inbox Classic.
