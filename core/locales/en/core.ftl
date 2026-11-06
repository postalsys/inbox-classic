# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.

## Counts and sizes

messages = { $count ->
    [one] 1 message
   *[other] { $count } messages
}
# the separator of decimals in sizes: 2.4 MB
decimal-separator = .
size-bytes = { $count ->
    [one] 1 byte
   *[other] { $count } bytes
}
size-kb = { $size } KB
size-mb = { $size } MB
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, { $unread } unread
list-counts-selected = { $messages }, { $unread } unread, { $selected } selected
# the status bar while searching: "12 found, 3 unread"
list-counts-found = { $found } found, { $unread } unread
list-counts-found-selected = { $found } found, { $unread } unread, { $selected } selected
list-counts-none = No messages found

## Special folders, as Outlook Express names them

folder-inbox = Inbox
folder-sent = Sent Items
folder-deleted = Deleted Items
folder-drafts = Drafts
folder-junk = Junk E-mail
folder-archive = Archive

## The reading pane

reader-no-message = There is no message selected.
reader-downloading = Downloading the message…
reader-downloading-detail = It is shown here as soon as it has arrived.
reader-failed = The message could not be downloaded
reader-failed-network = The mail server could not be reached ({ $reason }).
reader-failed-sign-in = The mail server did not accept the sign-in ({ $reason }). Check the password or sign in again in File > Accounts.
reader-failed-security = The connection to the mail server could not be made secure ({ $reason }).
reader-failed-other = The mail server answered: { $reason }.
reader-retry-note = Not downloaded. It is tried again once the account is back online.
reader-unreadable = This message can not be shown: { $error }
message-source-title = Message Source: { $subject }
message-source-untitled = Message Source

## Printing a message, and the header of a message quoted in a reply or forward

header-from = From
header-date = Date
header-to = To
header-cc = Cc
header-sent = Sent
header-subject = Subject
quote-original = ----- Original Message -----
fold-show-earlier = Show the earlier messages

## Several messages selected

selection-title = { $count ->
    [one] 1 message selected
   *[other] { $count } messages selected
}
selection-unread = { $count } unread
selection-flagged = { $count } flagged
delete-for-good-one = This message will be deleted for good. Delete it?
delete-for-good-all = These { $count } messages will be deleted for good. Delete them?
delete-for-good-some = { $count } of the { $total } messages will be deleted for good. Delete the messages?
done-read = { $count ->
   *[other] Marked { $messages } as read
}
done-unread = { $count ->
   *[other] Marked { $messages } as unread
}
done-flagged = { $count ->
   *[other] Flagged { $messages }
}
done-unflagged = Took the flag off { $messages }
done-deleted-for-good = { $count ->
   *[other] Deleted { $messages } for good
}
done-moved = { $count ->
   *[other] Moved { $messages } to { $folder }
}
done-copied = { $count ->
   *[other] Copied { $messages } to { $folder }
}
done-moving = { $count ->
   *[other] Moving { $messages } to { $folder }...
}
done-copying = { $count ->
   *[other] Copying { $messages } to { $folder }...
}
done-moved-back = { $count ->
   *[other] Moved { $messages } back to { $folder }
}
their-folders = their folders
undo-move = Undo Move
undo-delete = Undo Delete
undo-junk = Undo Mark as Junk
undo-not-junk = Undo Mark as Not Junk
nothing-to-undo = There is nothing to undo.
messages-gone = The messages are no longer there.
folder-holds-no-messages = That folder does not hold messages.
no-junk-folder = This account has no Junk E-mail folder to move the messages to.
no-inbox-folder = This account has no Inbox folder to move the messages to.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
done-flagged-color = Flagged { $messages } { $color ->
    [red] red
    [orange] orange
    [yellow] yellow
    [green] green
    [blue] blue
    [purple] purple
   *[gray] gray
}
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Red
    [orange] Orange
    [yellow] Yellow
    [green] Green
    [blue] Blue
    [purple] Purple
   *[gray] Gray
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Move Message
   *[other] Move { $count } Messages
}
move-window-title-copy = { $count ->
    [one] Copy Message
   *[other] Copy { $count } Messages
}
move-window-prompt-move = { $count ->
    [one] Move the selected message to:
   *[other] Move the { $count } selected messages to:
}
move-window-prompt-copy = { $count ->
    [one] Copy the selected message to:
   *[other] Copy the { $count } selected messages to:
}
# the folders used last, over the folder tree
targets-recent = Recent
# the folder the messages are in, which can not be chosen
target-current = { $folder } (current)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Moving { $done } of { $messages } to { $folder }...
transfer-copying = Copying { $done } of { $messages } to { $folder }...
transfer-another-account = another account
transfer-folder-gone = the folder it was going to is no longer there
transfer-not-on-server = the message is no longer on the server
transfer-not-moved = { $count ->
   *[other] { $messages } could not be moved to another account: { $reason }
}
transfer-not-copied = { $count ->
   *[other] { $messages } could not be copied to another account: { $reason }
}
transfer-none-moved = No message could be moved
transfer-none-copied = No message could be copied

## Messages as files

export-not-in-time = the message could not be downloaded in time
export-not-saved = { $failed } of { $messages } could not be saved ({ $problems })
export-not-attached = the messages could not be attached: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
   *[other] Saved { $messages } to { $folder }
}
downloading-messages = { $count ->
   *[other] Downloading { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] Put { $messages } in { $folder }
}
import-not-put = These were not put in the folder:

    { $problems }

## Problems the windows show

error-store = local store: { $error }
error-not-found = not found
error-closed = shutting down
error-other-account = the browser signed in to { $email }, not to this account
error-in-use = it can not be removed while accounts sign in with it: { $accounts }
error-turned-off = this sign-in app is turned off for new accounts
error-folder-name = a folder name of 1 to 200 letters, without control characters
error-folder-separator = a folder name can not have "{ $separator }" in it on this server
error-folder-special = the Inbox and the special folders can not be renamed or deleted
error-no-recipients = the message has no recipients
error-bad-address = "{ $address }" is not an e-mail address
error-attachment = { $path } could not be read: { $error }
error-no-drafts = the account has no Drafts folder to save the message in
error-draft-attachment = an attachment of the draft could not be kept: { $error }
error-password-not-saved = the password could not be saved for the next start: { $error }
error-sign-in-not-saved = the new sign-in could not be saved for the next start: { $error }
error-import-unreadable = { $path } can not be read: { $error }
error-import-too-large = { $path } is larger than 50 MB
error-import-not-mail = { $path } is not an e-mail message
error-list-answered = the list answered { $status }
error-not-built = the message could not be built
error-outbox-waits = { $count ->
    [one] the message waits in the Outbox and is sent with the next Send/Recv
   *[other] { $count } messages wait in the Outbox and are sent with the next Send/Recv
}
error-draft-not-removed = the earlier draft of the message could not be removed from Drafts: { $reason }
error-sent-but = the message was sent, but { $problem }
error-sent-still-in-outbox = it is still in the Outbox: { $error }
error-sent-no-copy = no copy could be saved in Sent: { $reason }
error-no-password = no password for this account
error-no-sign-in = no sign-in for this account
error-provider-missing = this build can not sign in to { $provider }: is its sign-in app removed?
error-provider-servers = the servers of this account are not those it signs in to
error-app-scopes = { $reason }. The mail server did not take the sign-in app's token: check that the app's scopes give access to mail
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google has not verified Inbox Classic yet, so it lets only test users sign in with it. Use your own Google sign-in app or an app password, or turn it on in Sign-in Apps (File > Accounts) if you are a test user.
sign-in-off-other = It was turned off in Sign-in Apps (File > Accounts), where it can be turned on again.
sign-in-app-no-name = the sign-in app needs a name
sign-in-app-no-client = the client ID is missing
sign-in-app-no-scopes = the sign-in app needs the scopes that give mail access
sign-in-app-bad-host = the { $server } server is missing or not a host name
sign-in-app-plain = the { $server } server has to use SSL/TLS or STARTTLS
sign-in-app-not-checked = the issuer has not been checked yet
sign-in-app-issuer-changed = the issuer changed: type the client secret again, or remove it
sign-in-register-google = In Google Cloud Console, create an OAuth client of the type Desktop app, with the scope https://mail.google.com/ on its consent screen. While the app is in testing, only its test users can sign in.
sign-in-register-microsoft = In Microsoft Entra, register an app with the platform Mobile and desktop applications, the redirect URI http://localhost and public client flows allowed, and the delegated permissions IMAP.AccessAsUser.All, SMTP.Send and offline_access. For your organization only, use https://login.microsoftonline.com/<tenant ID>/v2.0 as the issuer.
sign-in-register-other = Register a native (public) client with the redirect URI below; the provider has to allow any port on it (RFC 8252). Add the scope the provider gives mail access with.

## Calendar invitations

repeats = Repeats
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Every day
       *[other] Every { $interval } days
    }
    [week] { $interval ->
        [one] Every week
       *[other] Every { $interval } weeks
    }
    [month] { $interval ->
        [one] Every month
       *[other] Every { $interval } months
    }
   *[year] { $interval ->
        [one] Every year
       *[other] Every { $interval } years
    }
}
# "Every week on Monday, Wednesday"
repeats-on = { $repeats } on { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [one] { $repeats }, once
   *[other] { $repeats }, { $count } times
}
day-monday = Monday
day-tuesday = Tuesday
day-wednesday = Wednesday
day-thursday = Thursday
day-friday = Friday
day-saturday = Saturday
day-sunday = Sunday

## AI agents

agent-level-read = Read mail: folders, the message list, search and messages
agent-level-organize = Organize mail: read state, flags, junk, moving, deleting to Deleted Items
agent-level-drafts = Write drafts for you to send
agent-level-send = Send mail, each message only after you say yes
agent-connect-title = { $program } wants to use your mail
agent-connect-detail = An AI agent asked to work with Inbox Classic. Choose what it may do and which accounts it may see; you can change this later under Tools > AI Agents.

    Agents read mail that other people wrote, and a message can try to trick them. Inbox Classic always asks you before an agent sends anything.
agent-reply-to = Reply to “{ $subject }”
agent-reply-all-on = Reply to all on “{ $subject }”
agent-forward-of = Forward of “{ $subject }”
agent-never-written-one = You have never written to { $address }.
agent-never-written-many = You have never written to { $count } of these addresses.
agent-send-title = { $program } wants to send this message
agent-send-detail = Check who it goes to and what it says. If you send it, it waits { $seconds } seconds in the Outbox, where you can still delete it.
agent-change-title = What { $program } may do
agent-change-allowed = Change what this program’s AI agents may do with your mail.
agent-change-refused = You turned this program away. Allow it to let its agents use your mail again.
agent-log-taken-back = { $entry } (taken back)
agent-files = Files: { $files }
agent-undo-refused = It can not be taken back.
agent-undo-refused-why = It can not be taken back: { $reason }.
agent-undo-impossible = this can not be taken back
agent-undo-not-in-folder = the message is no longer in that folder
agent-undo-not-arrived = the message is not in the folder it went to (yet)
agent-undo-sent = the message was sent already
agent-original-not-downloaded = the message answered is not downloaded yet: read it first
agent-turned-away = Turned away
agent-can-nothing = Nothing
agent-can-read = read
agent-can-organize = organize
agent-can-drafts = write drafts
agent-can-send = send with your yes
# "Read, organize and write drafts"
agent-can-list = { $first } and { $last }
agent-accounts = { $count ->
    [0] no accounts
    [one] 1 account
   *[other] { $count } accounts
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = This message can not be read.
agent-log-composed = Opened "{ $subject }" in a new message for you to finish
agent-log-refused = You did not send "{ $subject }"
agent-log-sent = Sent "{ $subject }" to { $to }
agent-log-draft = Saved the draft "{ $subject }"
agent-log-read = Marked read "{ $subject }"
agent-log-unread = Marked unread "{ $subject }"
agent-log-flagged = Flagged "{ $subject }"
agent-log-unflagged = Took the flag off "{ $subject }"
agent-log-deleted = Deleted "{ $subject }"
agent-log-moved = Moved "{ $subject }" to { $folder }
agent-log-junk = Marked "{ $subject }" as junk
agent-log-not-junk = Marked "{ $subject }" as not junk
agent-log-folder = Made the folder "{ $name }"
agent-log-unsubscribed = Unsubscribed from the list of "{ $subject }"

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = the provider gave no refresh token
sign-in-no-account = the provider did not say which account signed in
sign-in-not-finished = signing in has not finished
secrets-unavailable = { $store } is not available
secrets-unavailable-why = { $store } is not available: { $error }
secrets-windows = the Credential Manager
secrets-mac = the keychain
secrets-linux = the system keyring (Secret Service)
error-no-such-file = there is no such file
