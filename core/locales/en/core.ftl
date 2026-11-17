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
reader-failed-network = The mail server could not be reached ({ $reason }).
reader-failed-sign-in = The mail server did not accept the sign-in ({ $reason }). Check the password or sign in again in File > Accounts.
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
bounce-mailbox-full-do = Send it again in a few days, or let the person know another way. Large attachments are refused first.
bounce-spam-blocked = Refused as spam
bounce-spam-blocked-why = The receiving server took the message for spam.
bounce-spam-blocked-do = Send it again without what looks like spam, such as many links, shortened links or a large attachment. If it keeps happening, ask your mail provider.
bounce-virus-detected = Refused for a virus
bounce-virus-detected-why = The receiving server found a virus or other harmful content in the message or its attachments.
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
bounce-relay-denied-do = Check the outgoing server of the account in File > Accounts, and that it signs in.
bounce-auth-failure = Your sender address could not be verified
bounce-auth-failure-why = The receiving server could not confirm that the message really came from your domain (SPF, DKIM or DMARC).
bounce-auth-failure-do = Forward this notice to whoever runs mail for your domain: its settings need fixing. Sending through your provider’s own server may help meanwhile.
bounce-rate-limited = Too much mail at once
bounce-rate-limited-why = The receiving server takes fewer messages from your mail server for now.
bounce-rate-limited-do = Wait a while and send it again. When writing to many people, send to fewer at a time.
bounce-greylisting = Held back for a moment
bounce-greylisting-why = The receiving server asks unknown senders to try again a little later, a common check against spam.
bounce-greylisting-do = Nothing. Mail servers try again on their own, and the message is usually delivered within the hour.
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
   *[other] Put { $messages } in { $folder }
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
error-provider-servers = this account’s servers do not match its sign-in app’s servers
error-app-scopes = { $reason }. The mail server did not take the sign-in app’s token: check that the app’s scopes give access to mail
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google has not verified Inbox Classic yet, so it lets only test users sign in with it. Use your own Google sign-in app or an app password, or turn it on in Sign-in Apps (File > Accounts) if you are a test user.
sign-in-off-other = It was turned off in Sign-in Apps (File > Accounts), where it can be turned on again.
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
agent-undo-sent = the message was sent already
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
agent-encrypted = This message is encrypted. Only the user can read it, in Inbox Classic.
list-encrypted = Encrypted message
agent-log-composed = Opened “{ $subject }” in a new message for you to finish
agent-log-refused = You did not send “{ $subject }”
agent-log-sent = Sent “{ $subject }” to { $to }
agent-log-draft = Saved the draft “{ $subject }”
agent-log-read = Marked read “{ $subject }”
agent-log-unread = Marked unread “{ $subject }”
agent-log-flagged = Flagged “{ $subject }”
agent-log-unflagged = Took the flag off “{ $subject }”
agent-log-deleted = Deleted “{ $subject }”
agent-log-moved = Moved “{ $subject }” to { $folder }
agent-log-junk = Marked “{ $subject }” as junk
agent-log-not-junk = Marked “{ $subject }” as not junk
agent-log-archived = Archived “{ $subject }”
agent-log-folder = Made the folder “{ $name }”
agent-log-unsubscribed = Unsubscribed from the list of “{ $subject }”

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
cards-file-too-big = This file is too big to be an address book.
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
pgp-key-locked = Can not be used: the key that protects it is no longer in { $store }. Import its backup again.
pgp-source-own = Made in Inbox Classic
pgp-source-file = Imported from a file
pgp-source-paste = Pasted
pgp-source-attachment = From a message
pgp-source-vcard = From a contact card
pgp-source-wkd = From the sender's mail provider
pgp-source-keyserver = From keys.openpgp.org
pgp-source-autocrypt = From a message's Autocrypt header
pgp-error-no-store = Private keys are kept protected by { $store }, which can not be used: { $error }
pgp-error-wrong-passphrase = The passphrase is not right.
pgp-error-not-a-key = This is not an OpenPGP key.
pgp-error-too-large = The key is too large.
pgp-error-unusable = The key uses old or weak cryptography and can not be used.
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
pgp-error-mismatch = The private key does not belong to its public key. It may have been altered.
pgp-file-name-public = { $who } public key.asc
pgp-file-name-private = { $who } private key backup.asc
pgp-pending = A different key for { $address } was found on { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Signed by { $signer }, key verified
pgp-part-signed = Signed by { $signer } (key not verified)
pgp-part-other = Signed by { $signer }, who is not the sender
pgp-part-unknown-key = Signed, but the key is not known
pgp-part-not-signed = Not signed
pgp-part-not-checked = Signature not checked
pgp-part-encrypted = Encrypted. { $signature }
pgp-part-no-key = Encrypted to a key you do not have
pgp-part-changed = The encrypted part was changed on the way and is not shown
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
pgp-part-pictures-loaded = { $label }. Pictures were loaded from the internet
pgp-error-no-own-key = You have no key for { $address } to sign or encrypt with. Make one in Tools > Encryption Keys, or turn Sign and Encrypt off.
pgp-error-missing-keys = { $count ->
    [one] { $addresses } has no key to encrypt to.
   *[other] These recipients have no key to encrypt to: { $addresses }.
}
pgp-error-encrypted-quote = This message quotes or forwards an encrypted message, so it can only be sent encrypted. Turn Encrypt on, or remove the quoted text.
pgp-error-protect = The message could not be signed or encrypted: { $reason }
pgp-found-keys = Found the key of { $addresses }.
pgp-found-none = No key was found for { $addresses }. Ask them to send you their public key.
pgp-found-no-key = No key was found.
pgp-find-unavailable = Keys could not be looked up now: { $error }
pgp-publish-pending = keys.openpgp.org sent a confirmation link to { $addresses }. Your key is published there once you click it.
pgp-publish-done = Your key is published on keys.openpgp.org for { $addresses }.
pgp-publish-failed = The key could not be published: { $error }
pgp-keyserver-off = Looking up keys on keys.openpgp.org is turned off in { $settings }.
pgp-details-part = Part { $number }: { $label }
pgp-details-signed = Signed { $when } with the key { $key }
pgp-details-unknown-key = Signed with the key { $key }, which you do not have
pgp-details-opened = Encrypted to your key { $key }
pgp-details-for = Encrypted to { $keys }
pgp-details-plain = Not signed and not encrypted
pgp-bar-parts = This message has { $count } parts: { $list }. Each part says how it is protected.
pgp-bar-count-verified = { $count } verified
pgp-bar-count-good = { $count ->
    [one] 1 signed or encrypted
   *[other] { $count } signed or encrypted
}
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
setup-account-secret-token = Its sign-in is in the file.
setup-account-asks-password = It asks for its password after the import.
setup-account-signs-in-again = You sign in to it again after the import.
setup-account-here = It is set up here already, so it is skipped.
setup-account-no-app = It signs in with { $app }, which is not set up here. Import the sign-in apps too.
setup-invalid-address = "{ $address }" is not an email address.
setup-invalid-server = The { $server } server has no usable name or port.
setup-invalid-user = It has no user name.
setup-invalid-sign-in = It signs in in a way Inbox Classic does not know.
setup-error-empty = The file is empty.
setup-error-too-large = The file is too large to be an Inbox Classic setup.
setup-error-not-setup = This file is not an Inbox Classic setup.
setup-error-damaged = The setup file is damaged and can not be read.
setup-error-newer = This setup was saved by a newer Inbox Classic ({ $version }). Update Inbox Classic, then import it again.
setup-error-needs-passphrase = This setup is protected by a passphrase. Type the passphrase it was saved with.
setup-error-wrong-passphrase = That is not the passphrase this setup was saved with.
setup-error-changed = The setup file was changed or damaged after it was saved, so it can not be imported.
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
    [one] 1 message rule moves messages to a folder that appears once its account syncs.
   *[other] { $count } message rules move messages to folders that appear once their accounts sync.
}
setup-added-trusted-senders = { $count ->
    [one] Added 1 trusted sender.
   *[other] Added { $count } trusted senders.
}
setup-nothing = Nothing was imported.
setup-account-servers = { $imap } and { $smtp } ({ $signin })
setup-file-name = Inbox Classic settings and accounts
setup-skipped-unreachable = { $name } was skipped: its sign-in service could not be reached. Add it again in Sign-in Apps.
attachment-runs-programs = “{ $name }” can run programs, so Inbox Classic does not open it. Save it, then open it yourself if you trust where it comes from.
attachment-decrypted-note = This attachment comes from an encrypted message. To open it, Inbox Classic stores it decrypted on this computer, in a folder of yours that Inbox Classic empties after a day.
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
