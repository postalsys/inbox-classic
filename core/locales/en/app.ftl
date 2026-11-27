# The words of the windows, the same on every platform. An & marks the letter of a menu item that Alt and the letter
# choose on Windows and Linux (&& is an ampersand); the Mac leaves it out. Put it on a letter of your word, a different
# one for each item of a menu where you can.

## The menus

menu-file = &File
menu-edit = &Edit
menu-view = &View
menu-tools = &Tools
menu-message = &Message
menu-help = &Help
menu-layout = &Layout
menu-sort-by = Sort &By
menu-text-size = &Text Size
menu-folder = F&older
menu-insert = &Insert

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &New Account...
cmd-exit = E&xit
cmd-sync = Send and Recei&ve All
cmd-sign-in-again = Sign &In Again...
cmd-mark-read = &Mark as Read
cmd-mark-unread = Mark as U&nread
cmd-pictures = Download &Pictures
cmd-about = &About Inbox Classic
cmd-new-mail = &New Message
cmd-reply = &Reply to Sender
cmd-reply-all = Repl&y to All
cmd-forward = &Forward
cmd-help = &Contents
cmd-delete = &Delete Message
cmd-move = Mo&ve to Folder...
cmd-flag = F&lag Message
cmd-new-folder = &New Folder...
cmd-rename-folder = &Rename Folder...
cmd-delete-folder = &Delete Folder
cmd-empty-folder = &Empty Folder
ui-empty-button = Empty
cmd-accounts = &Accounts...
cmd-find = &Find Message
cmd-save-as = &Save As...
cmd-print = &Print...
cmd-print-conversation = Print Con&versation...
cmd-import = &Import Messages...
cmd-outbox = &Outbox...
cmd-properties = P&roperties
cmd-mark-all-read = Mark &All Read
cmd-junk = Mark as &Junk
cmd-not-junk = Mark as N&ot Junk
cmd-archive = &Archive
cmd-watch-conversation = &Watch Conversation
cmd-ignore-conversation = &Ignore Conversation
cmd-next-message = &Next Message
cmd-previous-message = Pre&vious Message
cmd-next-unread = Next &Unread Message
cmd-go-to-folder = &Go to Folder...
cmd-find-in-message = Find in &This Message...
ui-go-to-prompt = Go to the folder:
ui-find-in-message-hint = Find in this message
ui-find-not-found = “{ $words }” is not in this message
cmd-expand-all-threads = &Expand All Conversations
cmd-collapse-all-threads = C&ollapse All Conversations
# The conversation shown in the reading pane: its next or previous message, and all of its messages open or folded
cmd-next-in-conversation = Ne&xt Message in Conversation
cmd-previous-in-conversation = Previous Message &in Conversation
cmd-open-all-messages = Open &All Messages
cmd-fold-all-messages = Fol&d All Messages
ui-group-by-conversation = &Group messages by conversation
ui-show-whole-conversation = Show the &whole conversation in the reading pane
ui-show-whole-conversation-note = Open a conversation’s messages together, including your replies, drafts and messages in other folders. Read messages are usually folded to a row. Use each message’s arrow to open or fold it.
ui-conversation-order = Conversation &order:
ui-conversation-oldest-first = Oldest first
ui-conversation-newest-first = Newest first
ui-thread-count = { $new ->
    [0] ({ $count })
   *[other] ({ $count }, { $new } new)
}
ui-conversation-to = to { $people }
ui-conversation-draft = Draft
ui-conversation-downloading = Downloading…
# Your own messages in a conversation shown in the reading pane, in place of your name
ui-conversation-you = You
# The line over a conversation in the reading pane: how many messages it has, then how many of them are unread
ui-conversation-messages = { $count ->
    [one] 1 message
   *[other] { $count } messages
}
ui-conversation-unread = { $count ->
    [one] 1 unread
   *[other] { $count } unread
}
# Over an open message of a conversation that is filed in another folder than the one it was opened from
ui-conversation-found-in = Found in { $folder }
# A row standing for read messages in the middle of a long conversation, folded away; a click lists them
ui-conversation-hidden = { $count ->
    [one] 1 more message
   *[other] { $count } more messages
}
# The arrow at the start of a message's row in a conversation, for screen readers
ui-conversation-open-message = Open message
ui-conversation-fold-message = Fold message
# A message's own button in a conversation: a menu of what else can be done with that message
ui-conversation-more = More
# A draft's own button in a conversation: opens it to go on writing
ui-conversation-edit = Edit
ui-conversation-elsewhere = { $count ->
    [one] This conversation also has a message in another folder.
   *[other] This conversation also has { $count } messages in other folders.
}
ui-conversation-this-folder = &This Folder Only
ui-conversation-whole = &Whole Conversation
cmd-folder-list = &Folder List
cmd-layout-automatic = &Automatic
cmd-layout-classic = &Classic
cmd-layout-columns = C&olumns
cmd-sort-date = &Date
cmd-sort-from = &From
cmd-sort-subject = &Subject
cmd-sort-size = Si&ze
cmd-sort-ascending = Sort &Ascending
cmd-sort-descending = Sort Desce&nding
cmd-text-size-largest = &Largest
cmd-text-size-larger = La&rger
cmd-text-size-medium = &Medium
cmd-text-size-smaller = &Smaller
cmd-text-size-smallest = Smalles&t
cmd-hide-ignored = &Hide Ignored Conversations
cmd-hide-read = Hide &Read Messages
cmd-notify = &Notify of New Mail
cmd-open = &Open Inbox Classic
cmd-default-app = Make &Default Mail App...
cmd-view-source = Message &Source
cmd-ai-agents = &AI Agents...
cmd-options = O&ptions...
cmd-message-rules = Message &Rules...
cmd-encryption-keys = Encr&yption Keys...
cmd-create-rule-from-message = Crea&te Rule from Message...
cmd-unsubscribe = &Unsubscribe from List...
cmd-select-all = Select A&ll
cmd-undo = &Undo
cmd-copy = &Copy to Folder...
cmd-address-book = Address &Book...
cmd-add-sender-to-book = Add Sender to Address Boo&k
cmd-import-address-book = Import Address &Book...
cmd-export-address-book = &Export Address Book...
cmd-export-setup = Export Settin&gs and Accounts...
cmd-import-setup = Import Se&ttings and Accounts...
cmd-compose-sign = Digitally &Sign
cmd-compose-encrypt = &Encrypt
cmd-attach-my-key = Attach My &Public Key

## The tray icon's menu

tray-check = &Check for New Mail
tray-no-accounts = No accounts yet

## Words the windows of more than one platform share

ui-tb-create-mail = Create Mail
ui-tb-reply = Reply
ui-tb-reply-all = Reply All
ui-tb-forward = Forward
ui-tb-print = Print
ui-tb-delete = Delete
ui-tb-junk = Junk
ui-tb-not-junk = Not Junk
ui-tb-archive = Archive
ui-tb-previous = Previous
ui-tb-next = Next
ui-previous-tip = Previous message
ui-next-tip = Next message
ui-tb-sync = Send/Recv
ui-tb-mark-read = Mark Read
ui-tb-mark-unread = Mark Unread
ui-still-running = Inbox Classic is still running
ui-no-subject = (no subject)
ui-quoted = “{ $subject }”
ui-newest-from = Latest message from { $sender }: { $subject }
ui-new-messages = { $count ->
    [one] { $count } new message
   *[other] { $count } new messages
}
ui-outbox-waiting = { $count ->
    [one] 1 message in the Outbox
   *[other] { $count } messages in the Outbox
}
ui-outbox-waits = { $subject } is waiting in the Outbox
ui-outbox-sending = Sending { $subject }...
ui-from-account = From { $account }
ui-sign-in-refused = Sign-in to { $account } was rejected or the session has expired.
ui-sign-in-again-ask = Sign in again in the browser?
ui-sign-in-again-failed = Could not sign in again: { $reason }
ui-unknown-reason = unknown reason
ui-checking = Checking for new messages on { $account }...
ui-done = Done
ui-sent-at = Sent { $subject } at { $time }
ui-draft-saved = Message saved in Drafts
ui-draft-not-saved = The message was not saved in Drafts: { $reason }
ui-about-core = Core { $version }
ui-add-account-first = Add a mail account first.
ui-add-account-first-link = Add a mail account first, then click the e-mail link again.
ui-default-app-is = Inbox Classic is your default mail app: e-mail links open a new message here.
ui-select-message-first = Select a message first.
ui-store-not-opened = The mail store could not be opened.
ui-store-or-cert-not-opened = The mail store or the certificate file could not be opened.
ui-help-title = Inbox Classic Help
ui-help-missing = The help is missing from this copy of Inbox Classic.
ui-ok = OK
ui-cancel = Cancel
ui-close = Close
ui-col-subject = Subject
ui-col-from = From
ui-col-to = To
ui-col-received = Received
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Watched conversation
ui-col-sent = Sent
ui-col-size = Size
ui-col-folder = Folder
ui-col-account = Account
ui-col-queued = Queued
ui-col-status = Status
ui-outbox-title = Outbox
ui-outbox-status-waiting = Waiting
ui-outbox-status-not-sent = Not sent: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Queued by an AI agent; scheduled for { $time }
ui-outbox-delete-ask = Delete this message without sending it?
ui-open-link = Open Link
ui-edit-link = Edit Link...
ui-remove-link = Remove Link
ui-insert-attachment = Insert Attachment
ui-insert-picture = Insert Picture
ui-filter-all = All files
ui-filter-pictures = Pictures
ui-filter-messages = Mail messages
ui-save-attachment-as = Save Attachment As
ui-not-sent = The message could not be sent.
ui-attachment-forgotten = You wrote “{ $word }”, but no file is attached. Send the message anyway?
ui-send-anyway = Send Anyway
ui-go-back = Go Back
ui-not-saved = The message could not be saved.
ui-saving-draft = Saving to Drafts...
ui-compose-saved-at = Saved in Drafts at { $time }
ui-compose-restored = Restored after Inbox Classic closed unexpectedly
ui-compose-not-saved = Not saved in Drafts: { $reason }
ui-save-changes-ask = Do you want to save changes to this message in Drafts?
ui-new-message-title = New Message
ui-link-invalid = Type a web address (https://...) or an e-mail link (mailto:...).
ui-link-address = Address:
ui-hyperlink = Hyperlink
ui-hyperlink-intro = The address the selected text links to.
ui-edit-hyperlink = Edit Hyperlink
ui-edit-hyperlink-intro = The link’s destination address. Clear the address to remove the link and keep the text.
ui-not-a-picture = The file could not be read as a PNG, JPEG, GIF or WebP picture no larger than 10 MB.
ui-format-color = Font Color
ui-format-numbers = Numbered List
ui-format-bullets = Bulleted List
ui-format-outdent = Decrease Indent
ui-format-indent = Increase Indent
ui-format-left = Align Left
ui-format-center = Center
ui-format-right = Align Right
ui-format-line = Insert Horizontal Line
ui-tb-send = Send
ui-tb-save = Save
ui-tb-attach = Attach
ui-tb-sign = Sign
ui-tb-encrypt = Encrypt
ui-field-keys = Keys:
ui-field-from = From:
ui-field-to = To:
ui-field-cc = Cc:
ui-field-bcc = Bcc:
ui-field-subject = Subject:
ui-field-attach = Attachments:
ui-signature = Signature
ui-signature-hint = Added to new messages, replies and forwards from this account.
ui-signature-not-saved = The signature could not be saved.
ui-all-inboxes = All Inboxes
ui-all-sent = All Sent
ui-all-drafts = All Drafts
ui-flagged-folder = Flagged
ui-all-folders = All Folders
ui-the-account = the account
ui-folder-name = Folder name:
ui-find-hint = Search mail
ui-find-tip = Searches message subjects, senders, recipients, attachment names and message text.
ui-clear-search = Clear search
ui-no-match = No messages match “{ $words }”.
ui-no-match-all = The search covers subjects, senders, recipients, attachment names and message text in all folders. Check the spelling or try fewer words.
ui-no-match-in = The search in { $folder } covers subjects, senders, recipients, attachment names and message text. Check the spelling or try fewer words.
ui-no-items = There are no items in this view.
ui-choose-folder = Choose a folder to see its messages.
ui-unsubscribe = Unsubscribe
ui-open-in-calendar = Open in Calendar
ui-pictures-blocked = Some pictures have been blocked to limit tracking by the sender.
ui-not-shown = The message could not be shown.
ui-attachment-not-read = The attachment could not be read.
ui-attachment-not-saved = The attachment could not be saved.
ui-not-downloaded = The message is not downloaded yet.
ui-leave-list = Leave this mailing list?
ui-leave-one-click = Inbox Classic will send an unsubscribe request to { $target }. No web page will open and no e-mail will be sent.
ui-leave-mail = To unsubscribe, send an e-mail to { $target }. Inbox Classic will prepare it for you. Send the message to confirm.
ui-leave-web = The mailing list’s unsubscribe page will open in your browser ({ $target }).
ui-unsubscribing = Sending an unsubscribe request to { $target }...
ui-cannot-unsubscribe = This message does not provide an unsubscribe option.
ui-unsubscribed = The mailing list has accepted the unsubscribe request.
ui-not-unsubscribed = Could not unsubscribe: { $reason }
# the bar over a message of a mailing list. It names the list by a domain only, never by a name the sender chose
ui-list-bar = This message is from a mailing list ({ $domain }).
ui-list-bar-plain = This message is from a mailing list.
# $date is a day as the system writes it ("21 November 2026")
ui-list-bar-asked = You asked to unsubscribe from this list on { $date }.
# a message that arrived more than two days after the request: the list did not stop
ui-list-bar-came-after = You asked to unsubscribe on { $date }, but this message arrived more than two days later.
ui-list-bar-opened = You opened this list’s unsubscribe page on { $date }.
ui-list-bar-failed = The unsubscribe request failed: { $reason }
# the bar's button; it asks first
ui-unsubscribe-ask = Unsubscribe…
ui-unsubscribe-again = Unsubscribe Again…
ui-event-span = { $start } to { $end }
ui-event-floating = { $when } (as given, without time-zone conversion)
ui-invitation = Invitation: { $title }
ui-invitation-updated = Updated invitation: { $title }
ui-invitation-canceled = Canceled: { $title }
ui-invitation-answer = Response to an invitation: { $title }
ui-no-title = (no title)
ui-organizer = Organizer: { $name }
ui-invitation-not-read = The invitation could not be read.
ui-no-calendar = The invitation (.ics file) could not be opened. Check that a calendar app is associated with this file type.
ui-messages-not-changed = The messages could not be changed.
ui-new-folder-in-selected = The new folder will be created inside the selected folder.
ui-new-folder-at-top = The new folder will be created at the top level of the account.
ui-folder-not-created = The folder could not be created.
ui-folder-not-renamed = The folder could not be renamed.
ui-folder-not-deleted = The folder could not be deleted.
ui-rename-folder-intro = Enter a new name for the folder “{ $folder }”.
ui-properties-of = { $subject } Properties
ui-internet-headers = Internet headers for this message:
ui-save-messages-in = Save Messages In
ui-save-message-as = Save Message As
ui-import-choose-folder = First choose the folder to import the messages into.
ui-add-account-title = Add Mail Account
ui-accounts-title = Accounts
ui-security-none = None (unencrypted)
ui-field-required = { $field } is required.
ui-email-invalid = The e-mail address is not valid.
ui-ports-invalid = Ports are numbers from 1 to 65535.
ui-looking-up = Looking up the settings of { $domain }...
ui-found-none = Enter the account details supplied by your e-mail provider.
ui-found-change = Change these settings if your provider has supplied different ones.
ui-found-guess = No settings were found for this address. The suggested server names are guesses. Check them with your provider.
ui-found-mx = Inbox Classic recognized your e-mail provider and filled in its server settings.
ui-found-srv = These settings were found in the DNS records of your domain.
ui-found-autodiscover = These settings were found by Microsoft Autodiscover (Exchange).
ui-found-other = These settings were found for this address.
ui-app-password-needed = Provider: { $provider }. If your account supports app passwords, create one in its security settings and enter it in the Password field of the next form. Otherwise, use browser sign-in if available.
ui-app-password-open = Open { $provider }’s instructions in your browser?
ui-plain-warning = Without encryption, anyone who intercepts your network traffic can read your password and messages. Continue only if the connection is protected in another way. A local network alone does not provide encryption.
ui-continue-ask = Continue?
ui-add-sign-in-app = Add a sign-in app...
ui-turned-off = { $name } is turned off on this computer.
ui-off-here = Turned off on this computer.
ui-why = Why?
ui-more-sign-in = More sign-in options...
ui-other-account = To add another e-mail account, enter your e-mail address and the name recipients should see. Server settings will be looked up next.
ui-field-account-name = Account name:
ui-field-name = Display name:
ui-field-email = E-mail address:
ui-field-user = User name:
ui-field-password = Password:
ui-field-imap-host = Incoming (IMAP) server:
ui-field-imap-port = IMAP port:
ui-field-imap-security = IMAP security:
ui-field-smtp-host = Outgoing (SMTP) server:
ui-field-smtp-port = SMTP port:
ui-field-smtp-security = SMTP security:
ui-field-other-addresses = Other addresses you send from:
ui-field-verifiers = Trust sender checks from:
ui-sign-in-not-started = Signing in through the browser could not start.
ui-sign-in-in-browser = Sign in to { $account } in the browser window that opened, then come back here.
ui-sign-in-failed = Could not sign in: { $reason }
ui-account-not-saved = The account could not be saved.
ui-start-intro = Gmail, Google Workspace, Outlook.com and Microsoft 365: sign in on Google’s or Microsoft’s own page. Your password is typed there, never into Inbox Classic.
ui-start-intro-apps = Sign in through the browser with one of your sign-in apps (More sign-in options), or add any e-mail account with your name and address below.
ui-use-app-password = Use App Password
ui-the-provider = the provider
ui-provider-intro = Sign in to { $email } on { $provider }’s website. Your password is not shared with Inbox Classic. If your account allows app passwords for mail, you can also use one created in its security settings. Outlook.com and Microsoft 365 take only the browser sign-in.
ui-provider-intro-apps = Sign in to { $email } on { $provider }’s website using one of your sign-in apps (More sign-in options). If your account allows app passwords for mail, you can also use one created in its security settings. Outlook.com and Microsoft 365 take only the browser sign-in.
ui-finish = Finish
ui-logon = Logon
ui-enter-password = Enter the password of { $account }.
ui-signs-in-with = Sign-in app: { $app }. Sign-in takes place in the browser, and the account uses this app’s servers.
ui-keep-password = Leave the password field empty to keep your current password.
ui-remove-account = Remove Account
ui-remove-account-ask = Remove this account from Inbox Classic? Its local data, including messages waiting in the Outbox and saved sign-in credentials, will be removed. Mail on the server will stay there.
ui-col-email = E-mail address
ui-col-incoming = Incoming server
ui-type-email = Type your e-mail address, name@example.com.
ui-ai-agent = AI Agent
ui-ai-agent-access = AI Agent Access
ui-ai-agents = AI Agents
ui-program-path = Program: { $path }
ui-it-may = Allowed actions:
ui-accounts-it-may-use = Allowed accounts:
ui-send-message-ask = Send Message?
ui-col-name = Name
ui-never = Never
ui-connect-agent = Connect an AI Agent
ui-connect-agent-intro = Add this to the MCP servers of your agent (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Program
ui-col-may = Permissions
ui-col-last-used = Last used
ui-col-when = When
ui-col-what = Action
ui-sign-in-app = Sign-in App
ui-sign-in-apps = Sign-in Apps
ui-add-sign-in-app-title = Add Sign-in App
ui-preset-app-name = { $provider } sign-in app
ui-issuer-not-checked = the issuer can not be checked
ui-checking-issuer = Checking { $issuer }...
ui-issuer-unusable = The issuer can not be used: { $reason }
ui-issuer-usable = The issuer can be used.
ui-sign-in-app-not-saved = The sign-in app could not be saved: { $reason }
ui-check = C&heck
ui-fill-in-for = Use settings for:
ui-app-name = Name:
ui-issuer = Issuer:
ui-client-id = Client ID:
ui-client-secret = Client secret:
ui-scopes = Scopes:
ui-imap-server = IMAP server:
ui-smtp-server = SMTP server:
ui-redirect-uri = Redirect URI:
ui-sign-in-app-intro = A sign-in app is an OAuth client you register with your provider to sign in through the browser. Choose a provider to fill in its settings, then add the client ID and client secret, if your provider supplied one.
ui-remove-secret = A client secret is saved. Enter a new one to replace it, or remove the saved secret
ui-register-it = Register the app with your provider
ui-built-in-note = { $name } is built in. You can only change whether it is offered for new accounts.
ui-client-with-secret = Client ID: { $client }, with a client secret.
ui-client-public = Client ID: { $client }, a public client (no secret).
ui-no-accounts = No accounts
ui-remove-sign-in-app = Remove Sign-in App
ui-remove-sign-in-app-ask = Remove the sign-in app { $name } and its saved client secret?
ui-sign-in-app-not-removed = The sign-in app was not removed. { $reason }
ui-sign-in-apps-intro = Sign-in apps let accounts sign in through the browser. One that is not checked is not offered for new accounts; the accounts that already use it keep working.
ui-col-issuer = Issuer
ui-col-used-by = Used by
ui-options-system-default = System default ({ $language })
# the settings window (core/settings.toml): its pages and the titles of its groups, Windows' Apply, and the words of
# the language the three platforms share
ui-settings-general = General
ui-settings-reading = Reading
ui-settings-new-mail = New Mail
ui-settings-sending = Sending
ui-settings-default-apps = Default Apps
ui-settings-message-list = Message List
ui-settings-messages = Messages
ui-settings-encryption = Encryption
ui-settings-language = Language
# a group's title as the label before its first control, in the Mac's panes: the colon as the language writes it
ui-settings-label = { $label }:
ui-apply = &Apply
ui-settings-sync = Sync
ui-sync-note = Keep your accounts, keys, Address Book, rules and settings the same on every computer, through a folder or storage you own. Everything is encrypted with your sync passphrase before it leaves this computer.
ui-sync-place = Synced through:
ui-sync-status = Status:
ui-sync-set-up = &Set Up Sync…
ui-sync-now = Sync &Now
ui-sync-computers = Co&mputers…
ui-sync-history = &History…
ui-sync-turn-off = &Turn Off Sync…
ui-sync-what = What to sync
ui-sync-what-note = Passwords, sign-ins and private keys travel only encrypted. Leave out what should stay on this computer.
ui-sync-accounts = Acc&ounts
ui-sync-passwords = Pass&words
ui-sync-sign-ins = Sign-&ins with Google, Microsoft and sign-in apps
ui-sync-sign-in-apps = Sign-in a&pps
ui-sync-app-secrets = Sign-in app se&crets
ui-sync-contacts = A&ddress Book
ui-sync-keys = &Keys
ui-sync-private-keys = Your p&rivate keys
ui-sync-rules = R&ules
ui-sync-trusted = Trusted send&ers
ui-sync-settings = Settin&gs
ui-sync-preferences = Layout and &view
ui-sync-everything = Everything
ui-sync-some-left-out = Some things left out
ui-sync-where = Where to keep it
ui-sync-folder = A folder
ui-sync-folder-note = Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud or Syncthing copies it to your other computers.
ui-sync-bucket = S3-compatible storage
ui-sync-bucket-note = Amazon S3, Cloudflare R2, Backblaze B2, MinIO or other storage that works like S3.
ui-sync-folder-label = &Folder:
ui-sync-folder-none = None chosen yet
ui-sync-choose-folder = &Choose…
ui-sync-choose-folder-title = Choose the Folder to Sync Through
ui-sync-endpoint = &Endpoint:
ui-sync-region = &Region:
ui-sync-bucket-name = &Bucket:
ui-sync-prefix = Folder in the b&ucket:
ui-sync-access-key = &Access key ID:
ui-sync-secret-key = &Secret access key:
ui-sync-next = &Next
ui-sync-join-title = Join Sync
ui-sync-join-note = This location already contains synced data. Enter the sync passphrase you chose on the first computer.
ui-sync-start-title = Start Sync
ui-sync-start-note = Choose a sync passphrase. You type it once on each computer you add. Keep it somewhere safe: without it, no other computer can join.
ui-sync-name = &Name of this computer:
ui-sync-merge-note = This computer’s data is merged with the synced data. Matching accounts and contacts become one.
ui-sync-turn-on = &Turn On Sync
ui-sync-on = Sync is on.
ui-sync-turn-off-ask = Turn off sync on this computer? Everything stays as it is, here and on your other computers. This computer just stops syncing.
ui-sync-turn-off-button = Turn Off
ui-sync-computers-title = Computers
ui-sync-computers-note = These computers sync through the same location. Remove a computer you no longer use to stop it syncing. Its synced data is kept.
ui-sync-this-computer = This computer
ui-sync-seen = Last synced { $when }
ui-sync-remove-ask = Remove “{ $name }” from sync? It stops syncing the next time it tries. To sync it again, set up sync on it once more.
ui-sync-loading = Reading…
ui-sync-history-title = History
ui-sync-history-note = When changes from different computers conflict, sync keeps one version. Replaced values appear here; restore one to use it again. Passwords, sign-in credentials and private keys are not kept here.
ui-sync-history-empty = No changes were replaced.
ui-sync-history-row = From { $source }, { $when }
ui-sync-restore = &Restore
ui-sync-restore-points = Restore points
ui-sync-restore-points-note = Restore points save your setup before sync removes items from this computer. Open one to choose what to restore.
ui-sync-restore-points-empty = None yet.
ui-sync-open-point = &Open…
# Set Up Sync on Windows: back from its second step to the first, as a wizard's Back button
win-sync-back = < &Back
ui-language-label = &Language:
ui-restart-note = Restart Inbox Classic to change the language.
ui-restart-ask = Inbox Classic shows { $language } once it restarts. Restart now?
ui-notify-new-mail = &Notify me when new mail arrives
ui-new-folder-title = New Folder
ui-rename-folder-title = Rename Folder
ui-delete-folder-question = Delete the folder “{ $folder }” with its messages and the folders in it? It is deleted on the server too.
ui-properties = Propertie&s
ui-account-sync = Send and Recei&ve
ui-account-properties = P&roperties...
ui-account-properties-of = A&ccount Properties...
ui-account-move-up = Move &Up
ui-account-move-down = Move Do&wn
ui-menu-open = &Open
ui-menu-flag = Fla&g
ui-menu-view-source = View So&urce
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = Unsu&bscribe from List...
ui-save-attachments = Save Attachments
ui-attachment-open = Open
ui-attachment-save-as = Save As...
ui-attachment-save-all = Save All...
# the strip's menu: a checked item for a picture or PDF file, drawn in the message (checked) or not
ui-attachment-show-in-message = Show in Message
# the strip's menu: imports the file, a key someone attached, into Encryption Keys
ui-attachment-import-key = Import Key...
ui-attachments-strip = Attachments
ui-attachment-note-title = Opening this file
ui-attachment-program-tip = Open is off for this kind of file: it can run programs. Save it to open it yourself.
ui-clear-flag = &Clear Flag
ui-button-move = &Move
ui-button-copy = &Copy
ui-find-folder = Find a folder
ui-new-folder-in = The new folder goes in { $folder }.
ui-outbox-send-all = &Send All Now
ui-yes = Yes
ui-no = No
ui-try-again = Try Again
ui-remove = &Remove
ui-signature-of = Signature - { $account }
ui-sign-in-with = Sign in with { $provider }
ui-sign-in-in-browser-yours = Sign in to your account in the browser window that opened, then come back here.
ui-browser-sign-in-server = { $server } (browser sign-in)
ui-dont-allow = Don’t Allow
ui-allow = &Allow
ui-dont-send = Don’t Send
ui-dont-unsubscribe = Don’t Unsubscribe
ui-edit-first = &Edit First
ui-new-address = New address
ui-turn-away = &Turn Away
ui-clear-agent-log = Clear the agents’ activity history?
ui-clear-agent-log-detail = This will not undo changes made by the agents.
ui-let-agents-connect = &Let AI agents connect to Inbox Classic
ui-change-button = Change…
ui-undo-button = Undo
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Undo Since…
ui-undo-since-span = Take back what this program did:
ui-take-back = Take Back
ui-rules-title = Message Rules
ui-rules-intro = Rules process new Inbox messages while Inbox Classic is running. Matching rules run in order. Once a rule plans to move a message out of the Inbox, no further rules apply to it.
ui-rules-none = No rules yet. Click New to make one.
ui-rule-new = &New...
ui-rule-edit = &Edit...
ui-rule-delete-button = De&lete
ui-rule-title = Message Rule
ui-rule-name = Name:
ui-rule-account = Account:
ui-rule-all-accounts = All accounts
ui-rule-query = Search criteria:
ui-rule-query-hint = Use search terms such as from:ann@example.com, subject:invoice or list:news.example.com, just as in the search box.
ui-rule-count = { $count ->
    [one] 1 Inbox message currently matches these criteria.
   *[other] { $count } Inbox messages currently match these criteria.
}
ui-rule-show = &Show
ui-rule-actions = Actions:
ui-rule-move = &Move it to:
ui-rule-mark-read = Mark it as &read
ui-rule-flag = &Flag it
ui-rule-archive = &Archive it
ui-rule-junk = Move it to &Junk E-mail
ui-rule-delete = &Delete it
ui-rule-quiet = Do &not notify me of it
ui-rule-apply-now = Also apply it to the messages already in the &Inbox
ui-rule-delete-ask = Delete the rule “{ $name }”?
ui-create-rule = Create Rule...
ui-rules-applied = { $count ->
    [one] 1 message processed by your rules
   *[other] { $count } messages processed by your rules
}
ui-col-rule-matches = Criteria
ui-clear-button = Cl&ear
ui-how-to-connect = How to Connect an Agent…
ui-agent-programs = Programs whose agents have requested access to your mail
ui-what-agents-did = Agent activity
ui-restart-now = &Restart Now
ui-restart-later = &Later

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = New Contact
ui-tb-new-group = New Group
ui-tb-properties = Properties
ui-tb-write-to = Write To
ui-menu-new-contact = New &Contact...
ui-menu-new-group = New &Group...
ui-menu-write-to = &Write To
ui-menu-delete = &Delete
ui-book-find-hint = Type a name or e-mail address
ui-book-all-contacts = All Contacts
ui-col-phone = Phone
# the Address Book list's key mark: its tooltip or the accessible name of a contact with an encryption key
ui-book-key-known = Has an encryption key
# the stronger mark: a key the user verified (compared its fingerprint with its owner)
ui-book-key-verified = Has a verified encryption key
ui-book-empty = The Address Book is empty. Click New Contact to add someone, or import a vCard or CSV file from the File menu.
ui-book-no-match = No contacts match “{ $words }”.
ui-book-delete-ask = { $count ->
    [one] Delete this contact from the Address Book?
   *[other] Delete these { $count } contacts from the Address Book?
}
ui-group-delete-ask = Delete the group “{ $name }”? The people in it stay in the Address Book.
ui-book-no-address = { $name } has no e-mail address.
ui-new-contact-title = New Contact
ui-contact-title = { $name } Properties
ui-contact-first = First name:
ui-contact-last = Last name:
ui-contact-display = Display name:
ui-contact-nickname = Nickname:
ui-contact-company = Company:
ui-contact-addresses = E-mail addresses:
ui-contact-address-hint = Type an e-mail address
ui-contact-add = &Add
ui-contact-set-default = Set as Defa&ult
ui-contact-default = { $address } (default)
ui-contact-phones = Phone numbers:
ui-phone-home = Home
ui-phone-work = Work
ui-phone-mobile = Mobile
ui-phone-other = Other
ui-contact-notes = Notes:
ui-contact-name-needed = Type a name or an e-mail address for the contact.
ui-contact-address-invalid = “{ $address }” is not a valid e-mail address.
ui-contact-not-saved = The contact could not be saved: { $reason }
ui-new-group-title = New Group
ui-group-title = { $name } Properties
ui-group-name = Group name:
ui-group-members = Members:
ui-group-select-members = &Select Members...
ui-group-new-member = Add an e-mail address that is not in the Address Book:
ui-group-name-needed = Type a name for the group.
ui-group-not-saved = The group could not be saved: { $reason }
ui-group-members-count = { $count ->
    [one] 1 member
   *[other] { $count } members
}
ui-select-recipients = Select Recipients
ui-select-members = Select Group Members
ui-pick-intro = Type a name or select it from the list:
ui-pick-recipients = Message recipients:
ui-pick-members = Group members:
ui-pick-to = &To →
ui-pick-cc = &Cc →
ui-pick-bcc = &Bcc →
ui-pick-add = &Add →
ui-pick-tip = Choose recipients from the Address Book
ui-filter-address-books = Address books (vCard, CSV)
ui-filter-vcard = vCard files
ui-book-export-name = Address Book
ui-book-imported = { $added ->
    [one] Added 1 contact
   *[other] Added { $added } contacts
}, { $skipped ->
    [one] skipped 1 already in the Address Book.
   *[other] skipped { $skipped } already in the Address Book.
}
ui-book-not-imported = The address book could not be imported: { $reason }
ui-book-exported = { $count ->
    [one] 1 contact saved to { $file }.
   *[other] { $count } contacts saved to { $file }.
}
ui-book-not-exported = The address book could not be saved: { $reason }
ui-code-copied = Copied the code
ui-codes-in-notifications = Show sign-in &codes in new mail notifications
ui-tool-unread-only = Unread
ui-no-unread = There are no unread messages here.
ui-pictures-always-sender = Always download pictures from { $sender }
ui-pictures-always-domain = Always download pictures from everyone at { $domain }
ui-pictures-unconfirmed = The sender’s domain ({ $domain }) could not be verified, so pictures in this message are not downloaded automatically.
ui-pictures-always-option = Download pictures in all &messages
ui-pictures-always-warning = Senders can then see when you read their messages.
ui-protection-details = &Details...
ui-protection-details-title = Security Details
ui-download-heading = Downloading
ui-download-ahead = &Download messages in advance:
ui-download-ahead-recent = Recent messages up to 1 MB each
ui-download-ahead-all = All messages
ui-download-ahead-never = Only when opened
ui-download-limit = &Storage limit per account:
ui-send-delay = Delay before &sending:
ui-send-delay-note = During the countdown, you can cancel sending with Undo. This option ends when the countdown expires, even if the message is still in the Outbox.
ui-dark-messages = Show messages on a dark background when the system is in dark mode
# Reading settings: previews of the pictures and PDF files attached, after a message's text
ui-preview-show = &Show attachments in messages
ui-preview-show-note = Shows pictures and the first pages of PDF files after the text of a message. Inbox Classic creates these previews without running code from the files or loading their external resources.
# the second setting under it; the same words as preview-pdf-option, with an access key
ui-preview-pdfs = Show PDF &files in messages
ui-sending-in = Sending { $subject } in { $count ->
    [one] 1 second
   *[other] { $count } seconds
}
ui-send-undone = { $subject } was not sent. The message has reopened for editing.
ui-send-too-late = Sending { $subject } can no longer be undone.
ui-outbox-status-undo = Scheduled to send at { $time }
ui-download-note = The limit applies to locally stored message content, not the whole database. The oldest copies are removed when it is exceeded and can be downloaded again when opened. Drafts and messages opened since the app started are kept even if they exceed the limit.
ui-attachment-downloading = This message has not finished downloading. Try again when the download is complete.
ui-trusted-senders-button = &Trusted Senders...
ui-trusted-senders-title = Trusted senders
ui-trusted-senders-note = Pictures in messages from these senders are downloaded automatically when your mail provider verifies the sender’s domain.
ui-trusted-everyone-at = Everyone at { $domain }
ui-trusted-senders-empty = No trusted senders have been added yet.
ui-search-encrypted = Search in &encrypted messages
ui-search-encrypted-note = With the required private keys available, downloaded or opened messages can be decrypted and indexed for text searches and protected subjects. This index is not encrypted. AI agents cannot search the decrypted content. Turning this off removes that content from the index.
ui-pgp-keyserver = Look &up keys on keys.openpgp.org
ui-pgp-keyserver-note = When looking up an address, Inbox Classic asks its domain first, then sends the address to keys.openpgp.org if needed. A lookup by fingerprint or key ID sends that identifier instead.
ui-eml-default = Open .&eml Files with Inbox Classic
ui-eml-default-done = Inbox Classic now opens .eml files.
ui-eml-default-failed = Inbox Classic could not be set as the default app for .eml files: { $reason }
ui-folders = Folders
ui-sorted-by = Sorted by { $field }
ui-layout-label = &Layout:
ui-columns-note = The window is wide enough for the column layout. You can change the layout under View > Layout.
ui-row-unread = Unread
ui-row-flagged = Flagged
ui-row-attachments = Has attachments
ui-row-encrypted = Encrypted
ui-row-signed = Signed
ui-row-messages = { $count ->
    [one] { $count } message
   *[other] { $count } messages
}
ui-list-pictures = Show senders’ &pictures in the message list
ui-list-pictures-note = In the column layout, shows brand logos or Address Book pictures when the sender’s domain is verified, and initials when no picture is available. Downloaded logos are cached and reused, with occasional refreshes.
ui-card-picture = Picture:
ui-card-picture-choose = C&hoose...
ui-picture-not-picture = The file could not be decoded as a PNG or JPEG picture.
ui-picture-too-large = This picture is too large. Choose one no larger than 10 MB, with a width and height of at most 8000 pixels.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Encryption Keys
ui-keys-intro = Your keys sign your messages and open mail encrypted to you. Your contacts' keys check their signatures and encrypt mail to them.
ui-keys-empty = No keys yet. Click New Key to make yours, or Import to add a key you already have.
ui-keys-col-name = Name
ui-keys-col-address = Address
ui-keys-col-kind = Kind
ui-keys-col-status = Status
ui-keys-kind-own = Your key
ui-keys-kind-contact = Contact
ui-keys-status-verified = { $status }, verified
ui-keys-new = &New Key...
ui-keys-import = &Import...
ui-keys-export = &Export...
ui-keys-backup = &Back Up...
ui-keys-verify = &Verify...
# My Keys: publishes the selected own key on keys.openpgp.org; N, I, E, B, V, P and R are taken in this window
ui-keys-publish = P&ublish...
# the question before publishing; { $addresses } are the key's addresses, separated by commas
ui-keys-publish-ask = Publish your public key on keys.openpgp.org so others can find it? Addresses on the key: { $addresses }. Each address must be confirmed through a link sent there before it is listed.
# the button that confirms that question on the Mac and Linux
ui-keys-publish-now = Publish
# My Keys: imports a key copied as text; N, I, E, B, V, P, R and U are taken in this window
ui-keys-paste = Import from C&lipboard
ui-keys-paste-none = The clipboard holds no OpenPGP key.
ui-keys-new-title = New Key
ui-keys-new-for = Make a key for:
ui-keys-new-make = &Make Key
ui-keys-no-account = Add a mail account first: a key is made for an account's addresses.
ui-keys-memory-only = Passwords are kept in memory only, so a private key made or imported now can not be used after Inbox Classic is closed.
ui-keys-backup-offer = Your new key is ready. Save a backup of it now? If this computer is lost or reset, the key can only come back from a backup.
ui-keys-backup-now = &Save a Backup...
ui-keys-later = &Later
ui-keys-backup-title = Back Up Key
ui-keys-backup-intro = The backup is protected by a passphrase. Keep the file and the passphrase in different safe places: you need both to bring the key back.
ui-keys-passphrase = &Passphrase:
ui-keys-passphrase-again = &Type it again:
ui-keys-passphrase-differ = The passphrases are not the same.
ui-keys-passphrase-short = Use a passphrase of at least 8 characters.
ui-keys-backup-saved = The backup was saved.
ui-keys-import-title = Import Key
ui-keys-import-passphrase = This private key is protected by a passphrase. Type it to import the key:
ui-keys-file-filter = OpenPGP keys
ui-keys-use-for = Use this key for { $addresses }? You can use it to sign messages from these addresses and read mail encrypted to it.
ui-keys-use = &Use It
ui-keys-not-now = &Not Now
ui-keys-remove-own = Remove your key { $fingerprint }? To decrypt mail protected with this key again, you will need to import its private-key backup. Copies already decrypted are not removed.
ui-keys-remove-contact = Remove the key associated with { $name }? You cannot check signatures made with this key or use it to encrypt mail until you add it again.
ui-key-properties-title = Key Properties
ui-key-names = Names:
ui-key-fingerprint = Fingerprint:
ui-key-status = Status:
ui-key-created = Created:
ui-key-expires = Expires:
ui-key-never = Never
ui-key-algorithm = Algorithm:
ui-key-source = Source:
ui-key-addresses = Addresses:
ui-key-address-verified = { $address } (verified)
ui-key-address-not-verified = { $address } (not verified)
ui-verify-title = Verify Key
ui-verify-intro = Ask { $name } to read you the fingerprint of their key from their own app, in person or on a call. Do not compare it with one sent by email: whoever could change the key could change that too.
ui-verify-fingerprint = The fingerprint of the key you have:
ui-verify-marks = { $count ->
    [0] This key has no e-mail address. Confirmation of its owner cannot be saved.
    [one] Before clicking They Match, confirm that this address belongs to the contact: { $addresses }. Otherwise, click They Differ.
   *[other] Before clicking They Match, confirm that all these addresses belong to the contact: { $addresses }. Otherwise, click They Differ.
}
ui-verify-match = They &Match
ui-verify-differ = They &Differ
ui-verify-differs = The key you have is not the one { $name } has. Remove it, and ask them for their key again.
ui-verify-unmark = Mark as &Not Verified
ui-account-security = Security
ui-account-security-intro = With a key, your messages can be signed, and people can send you encrypted mail.
ui-account-key = &Key for this account:
ui-account-key-none = None
ui-account-key-new = &New Key...
ui-account-autocrypt = &Send my public key with my messages (Autocrypt)
ui-contact-key = Encryption key:
ui-contact-key-none = No key
# a contact's key section: looks up the keys of the contact's addresses (their mail providers, then keys.openpgp.org)
ui-contact-find-key = &Find Key
ui-contact-key-use-new = Use the &New Key
ui-contact-key-keep = &Keep the Current One
ui-recipient-keys-title = Recipients’ Keys
ui-recipient-col-recipient = Recipient
ui-recipient-col-key = Key
ui-recipient-find-key = &Find Key
ui-recipient-remove = &Remove from Message
ui-send-unencrypted = Send &Without Encryption
ui-compose-make-key = &Make a Key...
ui-compose-show-keys = &Encryption Keys...
ui-compose-encrypt-off = &Turn Encryption Off
ui-compose-keep-encrypted = &Keep It Encrypted
ui-setup-export-title = Export Settings and Accounts
ui-setup-import-title = Import Settings and Accounts
ui-setup-export-intro = Choose what to take to another computer. The file contains no messages, including those in the Outbox. Only mail kept on the server can be downloaded on the other computer.
ui-setup-use-passphrase = Pr&otect the file with a passphrase
ui-setup-passphrase-note = A passphrase encrypts the whole file and allows it to include available passwords, sign-in tokens, client secrets and private keys from the selected items. Without this protection, these secrets are omitted and you will need to sign in again on the other computer.
ui-setup-export-button = &Export...
ui-setup-file-filter = Inbox Classic settings and accounts
ui-setup-ask-passphrase = This file is protected by a passphrase. Type it to see what the file holds:
ui-setup-import-intro = Choose what to import. Accounts already on this computer are left as they are.
ui-setup-from = Saved by Inbox Classic { $version } on { $date }.
ui-setup-import-button = &Import
ui-setup-done = Done
ui-setup-first-run = Import settings and accounts from another computer...
ui-first-run-other = Already use Inbox Classic on another computer? Bring its accounts and settings here.
ui-first-run-sync = Join Sync…
ui-first-run-import = Import from a File…
ui-reactions-label = Reactions:
ui-reaction-open-email = Open Reaction Email
ui-reaction-show-as-email = Show as Email
ui-reaction-when = Reacted { $when }
