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
# what goes between the items of a list of words (Read, organize and draft; Monday, Wednesday): a comma and a space
# here, 、 in Chinese and Japanese; the quotes keep the space, which a message would otherwise lose
list-separator = { ", " }
size-bytes = { $count ->
    [one] 1 byte
   *[other] { $count } bytes
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Off
send-delay-seconds = { $count ->
    [one] 1 second
   *[other] { $count } seconds
}
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
reader-downloading-detail = The message will appear here once the download is complete.
reader-downloading-size = The message is { $size }. It will appear here once it is downloaded.
reader-failed = The message could not be downloaded
reader-failed-network = The connection to the mail server could not be made or was interrupted ({ $reason }).
reader-failed-sign-in = The mail server did not accept the sign-in ({ $reason }). Check the password or sign in again in the account’s settings.
reader-failed-security = The connection to the mail server could not be made secure ({ $reason }).
reader-failed-other = The mail server answered: { $reason }.
reader-retry-note = It will be tried again when the account reconnects.
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
header-security = Security
header-part = Part { $number }
quote-original = ----- Original Message -----
fold-show-earlier = Show the earlier messages

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Your message was not delivered
bounce-delayed = Your message has not been delivered yet
bounce-delayed-note = Your mail server is still trying to deliver it. You do not need to send it again.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Show the message that bounced
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Show the delayed message
bounce-what-to-do = What you can do:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Nothing yet. If it still cannot be delivered, you will get another notice.
bounce-delayed-row-do = Nothing yet. Your mail server is still trying to deliver it, and you will get another notice if it cannot.
# folds the receiving server's own words
bounce-details = Details
# a recipient the notice does not name
bounce-someone = A recipient
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Reported by: { $server }
bounce-retry-minutes = The receiving server asked to wait { $count ->
    [one] a minute
   *[other] { $count } minutes
} before the next try.
bounce-retry-hours = The receiving server asked to wait { $count ->
    [one] an hour
   *[other] { $count } hours
} before the next try.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Blocklist: { $lists }
bounce-user-unknown = The address does not exist
bounce-user-unknown-why = The receiving server has no mailbox with this address. It may be mistyped, or the person may have moved on.
bounce-user-unknown-do = Check the spelling of the address, or ask the person for the address they use now.
bounce-invalid-address = The address is not valid
bounce-invalid-address-why = The address is not written in a form mail can be sent to.
bounce-invalid-address-do = Look for typing mistakes, such as a space, a missing letter or nothing after the @.
bounce-mailbox-disabled = The mailbox is closed
bounce-mailbox-disabled-why = The address exists, but its mailbox has been switched off or is no longer used.
bounce-mailbox-disabled-do = Reach the person another way and ask for an address they use now.
bounce-mailbox-full = The mailbox is full
bounce-mailbox-full-why = The recipient’s mailbox has no room for new mail.
bounce-mailbox-full-do = Send it again in a few days, or let the person know another way.
bounce-spam-blocked = Refused as spam
bounce-spam-blocked-why = The receiving server took the message for spam.
bounce-spam-blocked-do = Send it again without what looks like spam, such as many links, shortened links or a large attachment. If it keeps happening, ask your mail provider.
bounce-virus-detected = Refused for a virus
bounce-virus-detected-why = The receiving server reports a virus or other harmful content in the message or its attachments.
bounce-virus-detected-do = Check the attachments with a virus scanner. Some servers refuse every program or archive, so share such files as a link instead.
bounce-ip-blocklisted = Your mail server is on a blocklist
bounce-ip-blocklisted-why = The receiving server refuses mail from the server that sent yours, because that server’s address is on a blocklist.
bounce-ip-blocklisted-do = The message is not the problem. Forward this notice to your mail provider and ask them to have the server taken off the list.
bounce-domain-blocklisted = A domain is on a blocklist
bounce-domain-blocklisted-why = The receiving server refuses the message because your address’s domain, or a domain in the message’s links, is on a blocklist.
bounce-domain-blocklisted-do = If the message has links, try it without them. Otherwise forward this notice to whoever runs mail for your domain.
bounce-policy-blocked = Refused by the receiving server’s rules
bounce-policy-blocked-why = The rules of the receiving server do not let this message through, for example because of its size, its attachments or who sent it.
bounce-policy-blocked-do = The server’s own words under Details often give the reason. Ask the recipient whether they can accept such mail.
bounce-geo-blocked = Refused for where it came from
bounce-geo-blocked-why = The receiving server does not take mail from the country or network your mail server is in.
bounce-geo-blocked-do = Reach the person another way, or ask your mail provider about it.
bounce-relay-denied = The server would not pass it on
bounce-relay-denied-why = A server refused to deliver the message onward, often because it was sent without signing in or through a server that does not handle this recipient.
bounce-relay-denied-do = Check the outgoing server and sign-in details in the account’s settings.
bounce-auth-failure = Your sender address could not be verified
bounce-auth-failure-why = The receiving server could not confirm that the message really came from your domain (SPF, DKIM or DMARC).
bounce-auth-failure-do = Forward this notice to whoever runs mail for your domain: its settings need fixing. Sending through your provider’s own server may help meanwhile.
bounce-rate-limited = Too much mail at once
bounce-rate-limited-why = The receiving server takes fewer messages from your mail server for now.
bounce-rate-limited-do = Wait a while and send it again. When writing to many people, send to fewer at a time.
bounce-greylisting = Held back for a moment
bounce-greylisting-why = The receiving server asks unknown senders to try again a little later, a common check against spam.
bounce-greylisting-do = For a temporary delay, the sending server usually tries again. If this notice reports a final failure, try sending the message again later.
bounce-server-error = The receiving server had a problem
bounce-server-error-why = The receiving server could not be reached, or could not take the message because of a problem of its own.
bounce-server-error-do = Send it again later. If it keeps failing, check the part of the address after the @ for typing mistakes.
bounce-unknown = Not delivered
bounce-unknown-why = The notice does not say clearly why.
bounce-unknown-do = The server’s own words under Details may tell more. If they do not help, forward this notice to your mail provider.

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
done-archived = { $count ->
   *[other] Archived { $messages }
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
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Watching the conversation
   *[other] Watching { $count } conversations
}
done-unwatched = { $count ->
    [one] Stopped watching the conversation
   *[other] Stopped watching { $count } conversations
}
done-ignored = { $count ->
    [one] Ignoring the conversation
   *[other] Ignoring { $count } conversations
}
done-unignored = { $count ->
    [one] Stopped ignoring the conversation
   *[other] Stopped ignoring { $count } conversations
}
their-folders = their folders
undo-move = Undo Move
undo-delete = Undo Delete
undo-archive = Undo Archive
undo-junk = Undo Mark as Junk
undo-not-junk = Undo Mark as Not Junk
undo-send = Undo Send
nothing-to-undo = There is nothing to undo.
messages-gone = The messages are no longer there.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = This folder cannot contain messages.
not-archived-here = Messages in this folder can not be archived.
not-emptied-here = Only Deleted Items and Junk E-mail can be emptied.
next-unread-question = There are no more unread messages in { $folder }.

    Go to { $next }, the next folder with unread messages?
no-unread-left = There are no unread messages left.
empty-question = { $count ->
    [one] Empty { $folder }?

        The message in it is deleted for good. It can not be brought back.
   *[other] Empty { $folder }?

        The { $messages } in it are deleted for good. They can not be brought back.
}
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
download-progress = Downloading { $done } of { $total }
download-done = Downloaded { $size }
downloading-messages = { $count ->
   *[other] Downloading { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] Queued { $messages } for import into { $folder }
}
import-not-put = These were not put in the folder:

    { $problems }

## Problems the windows show

error-store = local store: { $error }
error-not-found = not found
error-closed = shutting down
error-other-account = the browser signed in to { $email }, not to this account
# a password or sign-in the mail server refused, with the server's words
failure-authentication = the server did not accept the sign-in ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = the connection to the server failed ({ $reason })
error-in-use = it can not be removed while accounts sign in with it: { $accounts }
error-turned-off = this sign-in app is turned off for new accounts
error-folder-name = the folder name must be 1 to 200 characters long and cannot contain control characters
error-folder-separator = a folder name can not have “{ $separator }” in it on this server
error-folder-special = the Inbox and the special folders can not be renamed or deleted
error-no-recipients = the message has no recipients
error-bad-address = “{ $address }” is not an e-mail address
error-not-own-address = { $address } is not one of this account’s sender addresses. Add it to “Other addresses you send from” in the account’s properties.
rule-query-refused = Rules cannot filter by folder or date ({ $words }).
rule-no-query = Enter search criteria for incoming messages.
rule-no-action = Choose at least one action for the rule.
error-attachment = { $path } could not be read: { $error }
error-no-drafts = the account has no Drafts folder to save the message in
error-draft-attachment = an attachment of the draft could not be kept: { $error }
error-password-not-saved = the password could not be saved for the next start: { $error }
error-sign-in-not-saved = the new sign-in details could not be saved for the next start: { $error }
error-import-unreadable = { $path } can not be read: { $error }
error-import-too-large = { $path } is larger than 50 MB
error-import-not-mail = { $path } is not an e-mail message
error-list-answered = the mailing list server returned status { $status }
error-not-built = the message could not be built
error-outbox-waits = { $count ->
    [one] the message remains in the Outbox; the next Send/Recv tries to send it again
   *[other] { $count } messages remain in the Outbox; the next Send/Recv tries to send them again
}
error-draft-not-removed = the earlier draft of the message could not be removed from Drafts: { $reason }
error-sent-but = the message was sent, but { $problem }
error-sent-still-in-outbox = it is still in the Outbox: { $error }
error-sent-no-copy = no copy could be saved in Sent: { $reason }
error-no-password = no password for this account
error-no-sign-in = no sign-in for this account
error-provider-missing = the sign-in app is unavailable in this build (ID: { $provider }). It may have been removed
error-provider-servers = this account’s servers do not match its sign-in app’s servers
error-app-scopes = { $reason }. The mail server did not take the sign-in app’s token: check that the app’s scopes give access to mail
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = The built-in Google sign-in app is set up for approved test users and is off for new accounts by default. Test users can turn it on in Sign-in Apps (File > Accounts). You can also use your own Google sign-in app, or an app password if your account supports it.
sign-in-off-other = It is turned off for new accounts. You can turn it on in Sign-in Apps (File > Accounts).
sign-in-app-no-name = the sign-in app needs a name
sign-in-app-no-client = the client ID is missing
sign-in-app-no-scopes = the sign-in app needs the scopes that give mail access
sign-in-app-bad-host = the { $server } server address is missing or is not a valid host name
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

agent-level-read = Read mail: folders, the message list, conversations, search, messages and their files, your message rules and the people you write to
agent-level-organize = Organize mail: read state, flags and their colors, junk, moving, archiving, creating and renaming folders, watching and ignoring conversations, deleting to Deleted Items, and leaving mailing lists after you say yes
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
agent-send-detail = Check the recipients and the message content. Once you confirm, the message waits { $seconds } seconds in the Outbox, where you can still delete it.
agent-change-title = What { $program } may do
agent-change-allowed = Change what this program’s AI agents may do with your mail.
agent-change-refused = You denied this program access. Allow it to give its agents access to your mail again.
agent-log-taken-back = { $entry } (taken back)
agent-files = Files: { $files }
agent-undo-refused = It can not be taken back.
agent-undo-refused-why = It can not be taken back: { $reason }.
agent-undo-impossible = this can not be taken back
agent-undo-not-in-folder = the message is no longer in that folder
agent-undo-not-arrived = the message is not in the folder it went to (yet)
agent-undo-sent = the message is no longer in the Outbox
agent-original-not-downloaded = the original message has not been downloaded yet. Open it first
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
agent-encrypted-original = This message is encrypted: an agent can not reply to it or forward it, as it can not encrypt.
agent-encrypted = This message is encrypted. AI agents cannot read its content. Open it in Inbox Classic to read it yourself.
agent-too-many-changes = Too many changes in the last 30 days: this agent has made as many as Inbox Classic keeps in its log for one program. It can make more once the oldest are 30 days old.
agent-too-many-reads = Too many reads in the last 30 days: this agent has read as much as Inbox Classic keeps in its log for one program. It can read more once the oldest reads are 30 days old.
list-encrypted = Encrypted message
agent-log-composed = Opened “{ $subject }” in a new message for you to finish
agent-log-refused = You did not send “{ $subject }”
agent-log-sent = Put “{ $subject }” in the Outbox for { $to }
agent-log-draft = Saved the draft “{ $subject }”
agent-log-draft-replaced = Replaced the draft “{ $subject }”
agent-log-draft-discarded = Requested deletion of the draft “{ $subject }”
agent-draft-note = { $program }, an AI agent, wrote this draft. Check the recipients and the text before you send it.
agent-log-read = Marked read “{ $subject }”
agent-log-unread = Marked unread “{ $subject }”
agent-log-flagged = Flagged “{ $subject }”
agent-log-unflagged = Took the flag off “{ $subject }”
agent-log-deleted = Deleted “{ $subject }”
agent-log-moved = Moved “{ $subject }” to { $folder }
agent-log-junk = Marked “{ $subject }” as junk
agent-log-not-junk = Marked “{ $subject }” as not junk
agent-log-archived = Archived “{ $subject }”
agent-log-folder = Requested creation of the folder “{ $name }”
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
agent-log-unsubscribed = You agreed to unsubscribe from the list of “{ $subject }”
agent-log-unsubscribe-failed = Could not unsubscribe from the list of “{ $subject }”: { $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
agent-log-unsubscribe-refused = You did not approve unsubscribe requests for { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } wants to unsubscribe you from a mailing list
   *[other] { $program } wants to unsubscribe you from { $count } mailing lists
}
agent-unsubscribe-detail = { $count ->
    [one] Inbox Classic asks the list below to stop sending to you, the one-click way it offers. Nothing else is sent, and the messages you have stay where they are.
   *[other] Inbox Classic asks each list below to stop sending to you, the one-click way the list offers. Nothing else is sent, and the messages you have stay where they are.
}
agent-log-flag-color = Flagged “{ $subject }” { $color ->
    [red] red
    [orange] orange
    [yellow] yellow
    [green] green
    [blue] blue
    [purple] purple
   *[gray] gray
}
agent-log-renamed = Requested renaming the folder “{ $old }” to “{ $name }”
agent-log-watched = Watched the conversation “{ $subject }”
agent-log-ignored = Ignored the conversation “{ $subject }”
agent-log-unmarked = Stopped watching or ignoring the conversation “{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = the message was changed since
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Marked 1 message read (search: { $query })
   *[other] Marked { $count } messages read (search: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Marked 1 message unread (search: { $query })
   *[other] Marked { $count } messages unread (search: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Flagged 1 message (search: { $query })
   *[other] Flagged { $count } messages (search: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Took the flag off 1 message (search: { $query })
   *[other] Took the flag off { $count } messages (search: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Flagged 1 message
   *[other] Flagged { $count } messages
} { $color ->
    [red] red
    [orange] orange
    [yellow] yellow
    [green] green
    [blue] blue
    [purple] purple
   *[gray] gray
} (search: { $query })
agent-log-bulk-moved = { $count ->
    [one] Moved 1 message to { $folder } (search: { $query })
   *[other] Moved { $count } messages to { $folder } (search: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Archived 1 message (search: { $query })
   *[other] Archived { $count } messages (search: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Marked 1 message as junk (search: { $query })
   *[other] Marked { $count } messages as junk (search: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Marked 1 message as not junk (search: { $query })
   *[other] Marked { $count } messages as not junk (search: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Deleted 1 message (search: { $query })
   *[other] Deleted { $count } messages (search: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] In the last 15 minutes
    [hour] In the last hour
    [hours] In the last 4 hours
    [day] In the last 24 hours
    [week] In the last 7 days
   *[all] In the last 30 days
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] { $program } has no changes in this period that can be taken back.
    [one] Try to take back the change recorded for { $program } in this period?
   *[other] Try to take back the { $count } recorded changes for { $program } in this period?
}
agent-undo-since-detail = Inbox Classic tries to restore folders, read states and flags, and delete messages still waiting in the Outbox. Changes that can no longer be undone are skipped. Some later flag-color changes can be overwritten.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Nothing was taken back.
    [one] Took back 1 recorded change, wholly or in part.
   *[other] Took back { $count } recorded changes, wholly or in part.
}
agent-undo-left-gone = { $count ->
    [one] 1 message was no longer where the change put it.
   *[other] { $count } messages were no longer where the change put them.
}
agent-undo-left-changed = { $count ->
    [one] 1 message was changed since, by you or on the server, and was left as it is.
   *[other] { $count } messages were changed since, by you or on the server, and were left as they are.
}
agent-undo-left-sent = { $count ->
    [one] 1 message had already left the Outbox.
   *[other] { $count } messages had already left the Outbox.
}
agent-undo-left-impossible = { $count ->
    [one] 1 change can not be taken back.
   *[other] { $count } changes can not be taken back.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] This message accepts the invitation “{ $summary }” ({ $when }).
    [tentative] This message tentatively accepts the invitation “{ $summary }” ({ $when }).
   *[decline] This message declines the invitation “{ $summary }” ({ $when }).
} It goes to the organizer named in the invitation. Your local answer changes once the mail server accepts the message, without confirmation from the organizer’s calendar.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Accepted: { $summary }
    [tentative] Tentative: { $summary }
   *[decline] Declined: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } has accepted this invitation.
    [tentative] { $name } has tentatively accepted this invitation.
   *[decline] { $name } has declined this invitation.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] read 1 message
   *[other] read { $count } messages
}
agent-reads-attachments = { $count ->
    [one] requested 1 attachment
   *[other] requested { $count } attachments
}
agent-reads-searches = { $count ->
    [one] searched once
   *[other] searched { $count } times
}
agent-reads-lists = { $count ->
    [one] looked at a message list once
   *[other] looked at message lists { $count } times
}
# each read under that row
agent-read-message = Read “{ $subject }”
agent-read-conversation = { $count ->
    [one] Read the conversation “{ $subject }” (1 message)
   *[other] Read the conversation “{ $subject }” ({ $count } messages)
}
agent-read-attachment = Requested the attachment “{ $name }” from “{ $subject }”
agent-read-search = { $count ->
    [one] Searched for “{ $query }”: 1 message
   *[other] Searched for “{ $query }”: { $count } messages
}
agent-read-people = Looked up people by name or address: “{ $query }”
agent-read-list = { $count ->
    [one] Looked at 1 list entry (scope: { $folder })
   *[other] Looked at { $count } list entries (scope: { $folder })
}
agent-read-changes = { $count ->
    [one] Looked at details of 1 new message
   *[other] Looked at details of { $count } new messages
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Programs started from { $terminal }
agent-terminal-programs-windows = Programs started from a terminal ({ $terminal })
agent-terminal-programs-linux = Programs started from a terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = A program started from { $terminal }
agent-terminal-program-windows = A program started from a terminal ({ $terminal })
agent-terminal-program-linux = A program started from a terminal ({ $terminal })
agent-connect-title-terminal = { $programs } want to use your mail
agent-connect-terminal-detail = AI agents started from the same recognized terminal program share the access you allow here. To give one separate access, add --name and a name of your choice to its arguments in the agent’s MCP settings. That name does not verify its identity.
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
agent-connect-claimed = It said it was { $claimed }. Inbox Classic checked which program started it: { $program }.

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
cards-file-too-big = This file exceeds the size limit for importing an address book.
ui-sender-added = { $name } was added to the Address Book.
ui-sender-known = { $name } is already in the Address Book.
ui-sender-none = The sender of this message has no e-mail address to add.
card-name-needed = The contact has no name and no e-mail address.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Code from { $domain }
otp-copy = Copy
otp-note = Enter it only on a page of { $domain }.
otp-old = This code was sent more than an hour before you opened it, and has probably expired.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } attendee
       *[other] { $count } attendees
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } is your code for { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Valid
pgp-key-expires = Valid until { $date }
pgp-key-expired = Expired on { $date }
pgp-key-revoked = Revoked
pgp-key-revoked-why = Revoked: { $reason }
pgp-key-not-valid = Not valid
pgp-key-locked = Cannot be used: its protection key is unavailable in { $store }. Check that the store is available and unlocked. If the protection key is missing, import the private-key backup.
pgp-source-own = Made in Inbox Classic
pgp-source-file = Imported from a file
pgp-source-paste = Pasted
pgp-source-attachment = From a message
pgp-source-vcard = From a contact card
pgp-source-wkd = From the sender's mail provider
pgp-source-keyserver = From keys.openpgp.org
pgp-source-autocrypt = From a message's Autocrypt header
pgp-error-no-store = The protection key for your private keys is kept in { $store }, which cannot be used: { $error }
pgp-error-wrong-passphrase = The passphrase is not right.
pgp-error-not-a-key = This is not an OpenPGP key.
pgp-error-too-large = The key is too large.
pgp-error-unusable = The key cannot be used. It may lack a suitable signing or encryption key, or use unsupported cryptography.
pgp-imported-private = { $count ->
    [one] Your private key was imported.
   *[other] { $count } private keys were imported.
}
pgp-imported-public = { $count ->
    [one] One key was imported.
   *[other] { $count } keys were imported.
}
pgp-imported-pending = Another key is already used for { $addresses }: the new one waits in the contact until you choose it.
pgp-error-needs-passphrase = The private key is protected by a passphrase. Type it to import the key.
# Import Key on a file attached to a message that holds a private key: keys from mail are taken as public keys only
pgp-error-attached-private = This attachment contains a private key. Only public keys can be imported directly from mail. To restore your own private key, save the attachment and import its file in Encryption Keys.
pgp-error-mismatch = The private key does not belong to its public key. It may have been altered.
pgp-file-name-public = { $who } public key.asc
pgp-file-name-private = { $who } private key backup.asc
pgp-pending = A different key for { $address } was found on { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Signed by { $signer }, key verified
pgp-part-signed = Signed by { $signer } (key not verified)
pgp-part-other = Signed by { $signer }, who is not the sender
pgp-part-unknown-key = Signed, but the key is not known
# the button beside that label: looks up the key that made the signature on keys.openpgp.org
pgp-part-find-key = Find Key
pgp-part-not-signed = Not signed
pgp-part-not-checked = Signature not checked
pgp-part-encrypted = Encrypted. { $signature }
pgp-part-no-key = Encrypted to a key you do not have
pgp-part-changed = The encrypted part failed its integrity check and is not shown
pgp-part-unprotected = Encrypted without protection against changes, not shown
pgp-part-broken = The encrypted part can not be read
pgp-why-mismatch = The signature does not match this text
pgp-why-weak-hash = The signature uses { $hash }, which is no longer safe
pgp-why-key-expired = Signed after the key expired on { $date }
pgp-why-key-revoked = Signed with a key that was revoked
pgp-why-not-signing-key = Signed with a key that may not sign
pgp-why-from-future = The signature is dated in the future
pgp-why-signature-expired = The signature has expired
pgp-why-key-not-valid = Signed with a key that is not valid
pgp-why-not-for-you = Signed for other recipients, and passed on to you
pgp-why-not-key-in-use = Signed with another key than the one in use for { $address }
pgp-part-pictures-loaded = { $label }. Pictures were loaded from the internet
pgp-error-no-own-key = You have no key for { $address } to sign or encrypt with. Make one in Tools > Encryption Keys, or turn Sign and Encrypt off.
pgp-error-missing-keys = { $count ->
    [one] No usable encryption key is available for this recipient: { $addresses }.
   *[other] No usable encryption keys are available for these recipients: { $addresses }.
}
pgp-error-encrypted-quote = This message contains text, pictures or attachments from encrypted mail and can only be sent encrypted. Turn Encrypt on, or remove all that content.
pgp-error-protect = The message could not be signed or encrypted: { $reason }
pgp-found-keys = Keys found for: { $addresses }.
pgp-found-none = No key was found for { $addresses }. Ask them to send you their public key.
pgp-found-no-key = No key was found.
pgp-find-unavailable = Keys could not be looked up now: { $error }
pgp-publish-pending = keys.openpgp.org sent a confirmation link to these addresses: { $addresses }. Confirm each address so your key can be found using that address.
pgp-publish-done = Your key is published on keys.openpgp.org for { $addresses }.
pgp-publish-failed = The key could not be published: { $error }
pgp-keyserver-off = Looking up keys on keys.openpgp.org is turned off in { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Will be encrypted and signed for you and { $addresses }.
   *[other] Will be encrypted and signed for you and its { $count } recipients.
}
pgp-compose-encrypt-ready = It will be encrypted and signed. Add recipients whose keys you have.
pgp-compose-missing = { $count ->
    [one] No usable key is available for { $addresses }, so the message cannot be encrypted yet.
   *[other] { $count } recipients have no usable key, so the message cannot be encrypted yet: { $addresses }.
}
pgp-compose-looking = Looking for the keys of { $addresses }...
pgp-compose-signed = Will be signed: recipients can check that the signed content has not changed. They must also verify who owns your key.
pgp-compose-reply-clear = Not encrypted, although the message it answers or forwards was.
pgp-compose-encrypted-files = Files of an encrypted message are attached, so this message can only be sent encrypted. Turn Encrypt on, or remove those files.
pgp-compose-sign-tip = Sign the message so recipients can check its content. They must also verify who owns your key
pgp-compose-sign-tip-encrypted = An encrypted message is always signed
pgp-compose-encrypt-tip = Encrypt the message, so only you and its recipients can read it
pgp-compose-make-key = You have no key for { $address } yet. Make one now? With it, your messages can be signed and encrypted.
pgp-compose-key-unusable = Your key for { $address } can not be used ({ $state }). Open Encryption Keys to import its backup or make a new key.
pgp-compose-encrypt-off-quote = This message contains text, pictures or attachments from encrypted mail. Without encryption, it cannot be sent until you remove all that content. Turn encryption off anyway?
pgp-compose-encrypt-off-reply = This message answers or forwards an encrypted message. Without encryption, anyone who handles your message on the way can read it. Turn encryption off?
pgp-recipient-verified = Key verified
pgp-recipient-found = Key not verified
pgp-recipient-own = Your own key
pgp-recipient-looking = Looking for a key...
pgp-recipient-missing = No key
pgp-recipient-not-found = No key: none was found on { $date }
pgp-recipient-unusable = Key can not be used: { $state }
pgp-recipients-intro = The message is encrypted to each recipient’s key, and to yours.
pgp-recipients-intro-missing = { $count ->
    [one] One recipient has no usable encryption key. Find a key or remove the recipient. Sending without encryption is available only after removing any content from encrypted mail.
   *[other] { $count } recipients have no usable encryption key. Find their keys or remove those recipients. Sending without encryption is available only after removing any content from encrypted mail.
}
pgp-details-part = Part { $number }: { $label }
attachment-from-part = From part { $number }: { $label }
pgp-details-signed = Signed { $when } with the key { $key }
pgp-details-unknown-key = Signed with the key { $key }, which you do not have
pgp-details-opened = Decrypted with your key { $key }
pgp-details-for = Encrypted to { $keys }
pgp-details-plain = Not signed and not encrypted
pgp-bar-parts = This message has { $count } parts: { $list }. Each part says how it is protected.
pgp-bar-count-verified = { $count } verified
pgp-bar-count-encrypted-signed = { $count } encrypted and signed
pgp-bar-count-encrypted = { $count } encrypted
pgp-bar-count-signed = { $count } signed
pgp-bar-count-warning = { $count ->
    [one] 1 needs attention
   *[other] { $count } need attention
}
pgp-bar-count-neutral = { $count } without a confirmed signature
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Settings
setup-part-preferences = Window preferences
setup-part-accounts = Accounts
setup-part-sign-in-apps = Sign-in apps
setup-part-contacts = Contacts and groups
setup-part-keys = Encryption keys
setup-part-rules = Message rules
setup-part-trusted-senders = Trusted senders
setup-holds-settings = { $count ->
    [one] 1 setting
   *[other] { $count } settings
}
setup-holds-preferences = { $count ->
    [one] 1 preference
   *[other] { $count } preferences
}
setup-holds-accounts = { $count ->
    [one] 1 account
   *[other] { $count } accounts
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 sign-in app
   *[other] { $count } sign-in apps
}
setup-holds-built-in = Which built-in sign-in apps are turned on
setup-holds-contacts = { $count ->
    [one] 1 contact
   *[other] { $count } contacts
}
setup-holds-groups = { $count ->
    [one] 1 group
   *[other] { $count } groups
}
setup-holds-own-keys = { $count ->
    [one] 1 key of your own
   *[other] { $count } keys of your own
}
setup-holds-contact-keys = { $count ->
    [one] 1 key of a contact
   *[other] { $count } keys of contacts
}
setup-holds-rules = { $count ->
    [one] 1 rule
   *[other] { $count } rules
}
setup-holds-trusted-senders = { $count ->
    [one] 1 trusted sender
   *[other] { $count } trusted senders
}
setup-sign-in-password = Password
setup-account-secret-password = Its password is in the file.
setup-account-secret-token = Its saved sign-in credentials are in the file.
setup-account-asks-password = It asks for its password after the import.
setup-account-signs-in-again = You sign in to it again after the import.
setup-account-here = It is set up here already, so it is skipped.
setup-account-no-app = It signs in with { $app }, which is not set up here. Import the sign-in apps too.
setup-invalid-address = "{ $address }" is not an email address.
setup-invalid-server = The { $server } settings have an invalid server name, port or security option.
setup-invalid-user = It has no user name.
setup-invalid-sign-in = Its sign-in method or configuration is not supported.
setup-error-empty = The file is empty.
setup-error-too-large = The setup file exceeds the size limit.
setup-error-not-setup = This file is not an Inbox Classic setup.
setup-error-damaged = The setup file is damaged and can not be read.
setup-error-newer = This setup was saved by a newer Inbox Classic ({ $version }). Update Inbox Classic, then import it again.
setup-error-needs-passphrase = This setup is protected by a passphrase. Type the passphrase it was saved with.
setup-error-wrong-passphrase = That is not the passphrase this setup was saved with.
setup-error-changed = The setup file failed its integrity check. It may be altered or damaged and cannot be imported.
sync-wrong-passphrase = That is not the sync passphrase of this vault. Type the one you chose when you set up sync on your first computer.
sync-place = { $place }, as “{ $name }”
sync-news-removed = { $count ->
    [one] Sync removed the account { $accounts }, as it was removed on another computer.
   *[other] Sync removed the accounts { $accounts }, as they were removed on another computer.
}
sync-news-lost = { $count ->
    [one] A change made at the same time on another computer was replaced by the one made here. The sync history keeps it.
   *[other] { $count } changes made at the same time on other computers were replaced by those made here. The sync history keeps them.
}
sync-status-busy = Syncing…
sync-status-never = Not synced yet.
sync-status-last = Last synced { $when }.
sync-status-today = Last synced today at { $time }.
sync-when-today = today at { $time }
sync-status-problem = Could not sync: { $problem }
sync-removed-here = This computer was removed from sync on another computer. Turn sync off, then set it up again to join.
sync-item-account = Account { $name }
sync-item-contact = Contact { $name }
sync-item-group = Group { $name }
sync-item-key = Key { $name }
sync-item-rule = Rule { $name }
sync-item-trusted = Trusted sender { $name }
sync-item-sign-in-app = Sign-in app { $name }
sync-item-settings = Settings
sync-another-computer = another computer
sync-no-key = This computer no longer has the key of the sync vault. Turn sync off and on again with the sync passphrase.
setup-error-read = The setup file could not be read: { $error }
setup-error-write = The setup could not be saved: { $error }
setup-error-no-parts = Choose at least one part.
setup-left-out = { $count ->
    [one] 1 entry of { $part } can not be used and is left out.
   *[other] { $count } entries of { $part } can not be used and are left out.
}
setup-imported-settings = The settings were replaced.
setup-imported-preferences = The window preferences were replaced.
setup-added-accounts = { $count ->
    [one] Added 1 account.
   *[other] Added { $count } accounts.
}
setup-skipped-here = { $address } is set up here already, so it was skipped.
setup-skipped-no-app = { $address } was skipped: it signs in with { $app }, which is not set up here.
setup-skipped-invalid = { $address } was skipped: { $reason }
setup-asks-password = { $address } asks for its password when it connects.
setup-signs-in-again = { $address } asks you to sign in again when it connects.
setup-added-sign-in-apps = { $count ->
    [one] Added 1 sign-in app.
   *[other] Added { $count } sign-in apps.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 sign-in app is set up here already.
   *[other] { $count } sign-in apps are set up here already.
}
setup-added-contacts = { $count ->
    [one] Added 1 contact to the address book.
   *[other] Added { $count } contacts to the address book.
}
setup-skipped-contacts = { $count ->
    [one] 1 contact is in the address book already.
   *[other] { $count } contacts are in the address book already.
}
setup-added-groups = { $count ->
    [one] Added or completed 1 group.
   *[other] Added or completed { $count } groups.
}
setup-added-own-keys = { $count ->
    [one] Added 1 key of your own.
   *[other] Added { $count } keys of your own.
}
setup-added-contact-keys = { $count ->
    [one] Added 1 key of a contact.
   *[other] Added { $count } keys of contacts.
}
setup-added-rules = { $count ->
    [one] Added 1 message rule.
   *[other] Added { $count } message rules.
}
setup-skipped-rules = { $count ->
    [one] 1 message rule is here already.
   *[other] { $count } message rules are here already.
}
setup-skipped-rules-account = { $count ->
    [one] 1 message rule is for an account that is not here, so it was skipped.
   *[other] { $count } message rules are for accounts that are not here, so they were skipped.
}
setup-rules-waiting = { $count ->
    [one] 1 message rule is waiting for its destination folder to be found during account synchronization.
   *[other] { $count } message rules are waiting for their destination folders to be found during account synchronization.
}
setup-added-trusted-senders = { $count ->
    [one] Added 1 trusted sender.
   *[other] Added { $count } trusted senders.
}
setup-nothing = Nothing was imported.
setup-account-servers = { $imap } and { $smtp } ({ $signin })
setup-file-name = Inbox Classic settings and accounts
setup-skipped-unreachable = { $name } was skipped: its sign-in service could not be reached or checked. Check the required app in Sign-in Apps before trying again.
attachment-runs-programs = “{ $name }” can run programs, so Inbox Classic does not open it. Save it, then open it yourself if you trust where it comes from.
attachment-decrypted-note = This attachment comes from encrypted mail. To open it in another app, Inbox Classic saves an unencrypted copy in a temporary folder for your user account. At startup, it tries to remove copies older than a day.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] The server did not move { $messages } to { $folder }, so it is back in { $from }: { $reason }
   *[other] The server did not move { $messages } to { $folder }, so they are back in { $from }: { $reason }
}
undone-delete = { $count ->
    [one] The server did not delete { $messages }, so it is back in { $from }: { $reason }
   *[other] The server did not delete { $messages }, so they are back in { $from }: { $reason }
}
undone-archive = { $count ->
    [one] The server did not archive { $messages }, so it is back in { $from }: { $reason }
   *[other] The server did not archive { $messages }, so they are back in { $from }: { $reason }
}
undone-read = { $count ->
    [one] The server did not mark { $messages } as read, so it is unread again: { $reason }
   *[other] The server did not mark { $messages } as read, so they are unread again: { $reason }
}
undone-unread = { $count ->
    [one] The server did not mark { $messages } as unread, so it is read again: { $reason }
   *[other] The server did not mark { $messages } as unread, so they are read again: { $reason }
}
undone-flags = { $count ->
    [one] The server did not change the flags of { $messages }, so it is as it was: { $reason }
   *[other] The server did not change the flags of { $messages }, so they are as they were: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# the reading option that turns PDF previews on and off (the apps show it)
preview-pdf-option = Show PDF files in messages
# the tile of a PDF file while PDF previews are off
preview-pdf-off = PDF files are not shown in messages.
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
preview-pdf-off-crashed = Inbox Classic closed while it was showing a file in a message, so PDF files are no longer shown in messages. Pictures still are. To show PDF files again, turn on { $option } in { $settings }.
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
preview-pdf-details = { $count ->
    [one] 1 page, { $size }
   *[other] { $count } pages, { $size }
}
# what a screen reader says of a page of a PDF file shown in a message
preview-page-alt = { $name }, page { $page } of { $count }
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
preview-more-pages = { $count ->
    [one] Open to see the page
   *[other] Open to see all { $count } pages
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
preview-more-files = { $count ->
    [one] 1 more file is in the list above
   *[other] { $count } more files are in the list above
}
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
preview-tile-downloading = Downloading…
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
preview-tile-preparing = Preparing…
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
preview-tile-format = { $format } pictures are not shown yet
# the tile of a PDF file that wants a password to open
preview-tile-password = Protected by a password: open it to enter the password
# the tile of a picture or PDF file over the size or pixel limit
preview-tile-too-large = Too large to show
# the tile of a file that is broken, or not what its name says
preview-tile-unreadable = Can not be shown
# the tile of a file that took too long to draw
preview-tile-timed-out = The preview took too long to prepare
# the tile of a file that closed the app once while it was drawn: never drawn again
preview-tile-crashed = Preview unavailable: an earlier attempt was interrupted
# the tile of a file while previews are paused after a file took too long, until the app starts again
preview-tile-off = Not shown until Inbox Classic starts again
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
preview-not-printed = { $name } ({ $details }) is not printed. Open it to print it.
