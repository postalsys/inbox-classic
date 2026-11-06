# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-tb-create-mail = Create Mail
win-tb-reply = Reply
win-tb-reply-all = Reply All
win-tb-forward = Forward
win-tb-print = Print
win-tb-delete = Delete
win-tb-junk = Junk
win-tb-not-junk = Not Junk
win-tb-sync = Send/Recv
win-tb-mark-read = Mark Read
win-tb-mark-unread = Mark Unread
win-flag-menu = Fla&g
win-still-running = Inbox Classic is still running
win-still-running-detail = It keeps checking for new mail here. Click the icon to open it, or right-click it to exit.
win-no-subject = (no subject)
win-quoted = “{ $subject }”
win-new-messages = { $count ->
    [one] { $count } new message
   *[other] { $count } new messages
}
win-newest-from = The newest from { $sender }: { $subject }
win-outbox-waiting = { $count ->
    [one] 1 message in the Outbox
   *[other] { $count } messages in the Outbox
}
win-outbox-waits = { $subject } waits in the Outbox
win-outbox-sending = Sending { $subject }...
win-from-account = From { $account }
win-sign-in-refused = The sign-in of { $account } was refused or ran out.
win-sign-in-again-ask = Sign in again in the browser?
win-sign-in-again-failed = Signing in again did not work: { $reason }
win-unknown-reason = unknown reason
win-checking = Checking for new messages on { $account }...
win-done = Done
win-sent-at = Sent { $subject } at { $time }
win-draft-saved = Message saved in Drafts.
win-draft-not-saved = The message was not saved in Drafts: { $reason }
win-about-core = Core { $version }
win-add-account-first = Add a mail account first.
win-add-account-first-link = Add a mail account first, then click the e-mail link again.
win-default-app-is = Inbox Classic is your default mail app: e-mail links open a new message here.
win-default-app-not-installed = This copy of Inbox Classic was not installed, so Windows does not list it as a mail app. Install it to choose it.
win-default-app-settings = Windows opens its Default apps settings for Inbox Classic. Choose it for MAILTO there.
win-select-message-first = Select a message first.
win-store-not-opened = The mail store could not be opened.
win-store-or-cert-not-opened = The mail store or the certificate file could not be opened.
win-no-unread = No unread messages
win-unread-messages = { $count ->
    [one] 1 unread message
   *[other] { $count } unread messages
}
win-help-title = Inbox Classic Help
win-help-missing = The help is missing from this copy of Inbox Classic.
win-print-failed = The message could not be printed.
win-print-title = Print
win-print-title-of = Print - { $subject }
win-no-bodies = Message bodies can not be shown.
win-webview-failed = Creating the WebView2 failed.
win-webview-missing = The WebView2 runtime is not available.

## Buttons and words used in many windows

win-ok = OK
win-cancel = Cancel
win-close = Close
win-delete-button = &Delete
win-find-label = &Find:
win-col-subject = Subject
win-col-to = To
win-col-from = From
win-col-received = Received
win-col-size = Size
win-col-folder = Folder
win-col-account = Account
win-col-queued = Queued
win-col-status = Status
win-save-as-button = Save &As...
win-too-many-files = Too many files at once: choose fewer.

## The Outbox

win-outbox-title = Outbox
win-outbox-status-waiting = Waiting
win-outbox-status-not-sent = Not sent: { $reason }
win-outbox-status-agent = Sent by an AI agent; goes at { $time }
win-outbox-delete-ask = Delete this message without sending it?
win-outbox-send-all = &Send All Now

## The compose window

win-editor-failed = Messages can not be written.
win-open-link = Open Link
win-edit-link = Edit Link...
win-remove-link = Remove Link
win-ctrl-click-to-open = ({ $ctrl }+click to open)
win-insert-attachment = Insert Attachment
win-insert-picture = Insert Picture
win-filter-all = All files
win-filter-pictures = Pictures
win-filter-messages = Mail messages
win-save-attachment-as = Save Attachment As
win-remove-file = &Remove
win-not-sent = The message could not be sent.
win-not-saved = The message could not be saved.
win-saving-draft = Saving to Drafts...
win-compose-saved-at = Saved in Drafts at { $time }
win-compose-not-saved = Not saved in Drafts: { $reason }
win-save-changes-ask = Do you want to save changes to this message in Drafts?
win-new-message-title = New Message
win-link-invalid = Type a web address (https://...) or an e-mail link (mailto:...).
win-link-address = Address:
win-hyperlink = Hyperlink
win-hyperlink-intro = The address the selected text links to.
win-edit-hyperlink = Edit Hyperlink
win-edit-hyperlink-intro = Where the link goes. Empty the address to remove the link and keep its text.
win-not-a-picture = This file is not a PNG, JPEG or GIF picture, or it is larger than 10 MB.
win-format-bold = Bold ({ $ctrl }+B)
win-format-italic = Italic ({ $ctrl }+I)
win-format-underline = Underline ({ $ctrl }+U)
win-format-color = Font Color
win-format-numbers = Numbered List
win-format-bullets = Bulleted List
win-format-outdent = Decrease Indent
win-format-indent = Increase Indent
win-format-left = Align Left
win-format-center = Center
win-format-right = Align Right
win-format-link = Hyperlink ({ $ctrl }+K)
win-format-line = Insert Horizontal Line
win-tb-send = Send
win-tb-save = Save
win-tb-attach = Attach
win-field-from = From:
win-field-to = To:
win-field-cc = Cc:
win-field-bcc = Bcc:
win-field-subject = Subject:
win-field-attach = Attach:
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature = Signature
win-signature-title = Signature: { $account }
win-signature-hint = Added to new messages, replies and forwards from this account.
win-signature-not-saved = The signature could not be saved.

## The folders, the message list and the reading pane

win-all-inboxes = All Inboxes
win-all-folders = All folders
win-the-account = the account
win-folder-name = Folder name:
win-find-hint = Search mail
win-find-tip = Finds words in the subject, the people, the file names and the text of messages.
win-clear-search = Clear search
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
win-no-match = No messages match “{ $words }”.
win-no-match-all = The search looks at the subject, the people, the file names and the text of the messages in every folder. Check the spelling, or try fewer words.
win-no-match-in = The search looks at the subject, the people, the file names and the text of the messages in { $folder }. Check the spelling, or try fewer words.
win-no-match-indexing = { $count ->
    [one] The text of { $count } message is still being indexed, so more may be found soon.
   *[other] The text of { $count } messages is still being indexed, so more may be found soon.
}
win-no-items = There are no items in this view.
win-choose-folder = Choose a folder to see its messages.
win-unsubscribe = Unsubscribe
win-open-in-calendar = Open in Calendar
win-files = { $count ->
    [one] { $count } file
   *[other] { $count } files
}
win-pictures-blocked = Some pictures have been blocked to help prevent the sender from identifying your computer. Click here to download pictures.
win-click-to-retry = Click here to try again.
win-not-shown = The message could not be shown.
win-save-attachments = &Save Attachments...
win-attachment-not-read = The attachment could not be read.
win-attachment-not-saved = The attachment could not be saved.
win-not-downloaded = The message is not downloaded yet.
win-files-not-saved = { $failed } of the { $count } files could not be saved.
win-leave-list = Leave this mailing list?
win-leave-one-click = Inbox Classic asks { $target } to stop sending it to you. No page opens and no message is sent.
win-leave-mail = The list wants a message to { $target }. Inbox Classic writes it for you; send it to unsubscribe.
win-leave-web = The list's page for it opens in your browser ({ $target }).
win-unsubscribing = Unsubscribing from { $target }...
win-cannot-unsubscribe = This message can not unsubscribe you.
win-unsubscribed = Unsubscribed. The list says it will stop sending this mail.
win-not-unsubscribed = Could not unsubscribe: { $reason }
win-event-span = { $start } to { $end }
win-event-floating = { $when } (the sender's time)
win-invitation = Invitation: { $title }
win-invitation-updated = Updated invitation: { $title }
win-invitation-canceled = Canceled: { $title }
win-invitation-answer = Answer to an invitation: { $title }
win-no-title = (no title)
win-organizer = Organizer: { $name }
win-attendees = { $count ->
    [one] { $count } attendee
   *[other] { $count } attendees
}
win-invitation-not-read = The invitation could not be read.
win-no-calendar = No calendar program on this computer opens invitations (.ics files).
win-messages-not-changed = The messages could not be changed.
win-copy-button = &Copy
win-move-button = &Move
win-new-folder-in-highlighted = The new folder goes in the highlighted folder.
win-new-folder-in-selected = The new folder goes in the selected folder.
win-new-folder-at-top = The new folder goes at the top of the account.
win-folder-not-created = The folder could not be created.
win-folder-not-renamed = The folder could not be renamed.
win-folder-not-deleted = The folder could not be deleted.
win-rename-folder-intro = The new name of the folder { $folder }.
win-delete-folder-ask = Delete the folder "{ $folder }" with its messages and the folders in it? It is deleted on the server too.
win-clear-flag = &Clear Flag
win-rename = &Rename...
win-open = &Open
win-view-source = View &Source
win-properties = Propert&ies
win-properties-of = { $subject } Properties
win-internet-headers = Internet headers for this message:
win-save-messages-in = Save Messages In
win-save-message-as = Save Message As
win-messages-not-saved = The messages could not be saved.
win-messages-not-forwarded = The messages could not be forwarded.
win-import-choose-folder = Choose the folder to put the messages in first.

## Accounts

win-add-account-title = Add Mail Account
win-accounts-title = Accounts
win-security-none = None (unencrypted)
win-field-required = { $field } is required.
win-email-invalid = The e-mail address is not valid.
win-ports-invalid = Ports are numbers from 1 to 65535.
win-looking-up = Looking up the settings of { $domain }...
win-found-none = Enter the account details your e-mail provider gave you.
win-found-change = Change them if your provider gave you others.
win-found-guess = No settings were found for this address: these are the usual names, check them with your provider.
win-found-mx = Your mail is handled by a provider Inbox Classic knows; these are its servers.
win-found-srv = These settings were found in the DNS records of your domain.
win-found-autodiscover = These settings were found by Microsoft Autodiscover (Exchange).
win-found-other = These settings were found for this address.
win-app-password-needed = { $provider } does not take your normal password in mail programs. Create an app password in your { $provider } account and type it in the Password field of the next form.
win-app-password-open = Open { $provider }'s instructions in your browser?
win-plain-warning = Without encryption your password and mail travel the network readable by anyone on the way. Use this only for a server on your own computer or network.
win-continue-ask = Continue?
win-sign-in-google = Sign in with Google
win-sign-in-microsoft = Sign in with Microsoft
win-add-sign-in-app = Add a sign-in app...
win-turned-off = { $name } is turned off on this computer.
win-off-here = Turned off on this computer.
win-why = Why?
win-more-sign-in = More sign-in options...
win-next = &Next >
win-other-account = Any other e-mail account: your name as others see it and your e-mail address. Its servers are looked up next.
win-field-name = Display name:
win-field-email = E-mail address:
win-field-user = User name:
win-field-password = Password:
win-field-imap-host = Incoming (IMAP) server:
win-field-imap-port = IMAP port:
win-field-imap-security = IMAP security:
win-field-smtp-host = Outgoing (SMTP) server:
win-field-smtp-port = SMTP port:
win-field-smtp-security = SMTP security:
win-sign-in-not-started = Signing in through the browser could not start.
win-your-account = your account
win-sign-in-in-browser = Sign in to { $account } in the browser window that opened, then come back here.
win-sign-in-failed = Signing in did not work: { $reason }
win-account-not-saved = The account could not be saved.
win-start-intro = Gmail, Google Workspace, Outlook.com and Microsoft 365: sign in on Google's or Microsoft's own page. Your password is typed there, never into Inbox Classic.
win-start-intro-apps = Sign in through the browser with one of your sign-in apps (More sign-in options), or add any e-mail account with your name and address below.
win-use-app-password = Use App Password
win-the-provider = the provider
win-provider-intro = { $email } signs in on { $provider }'s own page, without giving Inbox Classic your password. Or use an app password made in your account's security settings.
win-provider-intro-apps = { $email } can sign in on { $provider }'s own page with one of your sign-in apps (More sign-in options). Or use an app password made in your account's security settings.
win-finish = Finish
win-logon = Logon
win-enter-password = Enter the password of { $account }.
win-browser-sign-in = (browser sign-in)
win-signs-in-with = Signs in with: { $app }. It signs in through the browser and uses the servers of its sign-in.
win-keep-password = Leave the password empty to keep the one you have.
win-remove-account = Remove Account
win-remove-account-ask = Remove this account from Inbox Classic? Its mail stays on the server; the copy on this computer and the saved password are removed.
win-col-email = E-mail address
win-col-incoming = Incoming server
win-add = &Add...
win-properties-button = &Properties...
win-signature-button = Si&gnature...
win-sign-in-apps-button = Sign-in A&pps...
win-type-email = Type your e-mail address, name@example.com.

## AI agents

win-ai-agent = AI Agent
win-ai-agent-access = AI Agent Access
win-ai-agents = AI Agents
win-program-path = Program: { $path }
win-it-may = It may:
win-accounts-it-may-use = Accounts it may use:
win-allow = &Allow
win-dont-allow = &Don't Allow
win-turn-away = &Turn Away
win-send-message-ask = Send Message?
win-col-address = Address
win-col-name = Name
win-never-written-to = Never written to
win-send = &Send
win-edit-first = &Edit First
win-dont-send = &Don't Send
win-never = Never
win-forget-program-ask = Forget this program and what its agents did? It is asked about again the next time it connects.
win-clear-log-ask = Clear the list of what agents did? What they did stays done.
win-connect-agent = Connect an AI Agent
win-connect-agent-intro = Add this to the MCP servers of your agent (Claude Desktop: Settings > Developer > Edit Config):
win-let-agents-connect = &Let AI agents connect to Inbox Classic
win-agent-programs = &Programs whose agents asked to use your mail:
win-col-program = Program
win-col-may = May
win-col-last-used = Last used
win-change = &Change...
win-what-agents-did = &What agents did:
win-col-when = When
win-col-what = What
win-clear = C&lear
win-how-to-connect = How to connect an agent

## Sign-in apps

win-sign-in-app = Sign-in App
win-sign-in-apps = Sign-in Apps
win-add-sign-in-app-title = Add Sign-in App
win-preset-app-name = { $provider } sign-in app
win-issuer-not-checked = the issuer can not be checked
win-checking-issuer = Checking { $issuer }...
win-issuer-unusable = The issuer can not be used: { $reason }
win-issuer-usable = The issuer can be used.
win-sign-in-app-not-saved = The sign-in app could not be saved: { $reason }
win-check = Check
win-check-button = C&heck
win-copy = &Copy
win-fill-in-for = Fill in for:
win-app-name = Name:
win-issuer = Issuer:
win-client-id = Client ID:
win-client-secret = Client secret:
win-scopes = Scopes:
win-imap-server = IMAP server:
win-smtp-server = SMTP server:
win-redirect-uri = Redirect URI:
win-sign-in-app-intro = An OAuth client you registered with your provider, for accounts that sign in through the browser. Fill it in for a provider, then add the client ID (and secret, if the provider gave one).
win-remove-secret = A secret is saved; type another to replace it, or remove it
win-register-it = Register it with your provider
win-built-in-note = { $name } is built in: only whether it is used for new accounts can change.
win-client-with-secret = Client ID: { $client }, with a client secret.
win-client-public = Client ID: { $client }, a public client (no secret).
win-built-in = (built-in)
win-no-accounts = No accounts
win-remove-sign-in-app = Remove Sign-in App
win-remove-sign-in-app-ask = Remove the sign-in app { $name } and its saved client secret?
win-sign-in-app-not-removed = The sign-in app was not removed: { $reason }
win-sign-in-apps-intro = Sign-in apps let accounts sign in through the browser. One that is not checked is not offered for new accounts; the accounts that already use it keep working.
win-col-issuer = Issuer
win-col-used-by = Used by
win-edit = &Edit...

## Options

win-options-language-label = &Show Inbox Classic in:
win-options-system-default = System default ({ $language })
win-options-restart-note = Inbox Classic restarts to show another language.
win-options-notify = &Notify me when new mail arrives
win-restart-ask = Inbox Classic shows { $language } once it restarts. Restart now?
win-restart-now = &Restart Now
win-restart-later = &Later
