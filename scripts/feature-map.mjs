#!/usr/bin/env node
// Builds a single HTML page that maps every feature of the app to a screenshot from the UI end-to-end test
// (scripts/ui-e2e.ps1, copied here by scripts/win-ui-e2e.sh; the Mac's and Linux's take the same names), with the
// screenshots embedded:
//   node scripts/feature-map.mjs [screenshot dir, default build/ui-e2e] [output, default build/feature-map.html]
// With --check <windows|mac|linux> it writes no page but fails when a platform's test did not take the screenshot of a
// feature, unless `notYet` below lists it for that platform: a feature added to one app shows up as missing on the
// others until their tests show it too (CI runs this for each platform).

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const args = process.argv.slice(2);
const checkAt = args.indexOf('--check');
const checking = checkAt >= 0 ? args.splice(checkAt, 2)[1] : null;
const dir = args[0] || 'build/ui-e2e';
const out = args[1] || 'build/feature-map.html';
const version = /version = "([^"]+)"/.exec(readFileSync('core/Cargo.toml', 'utf8'))[1];

// each feature: the screenshot, what it does, how to reach it, and what the UI test checks
const sections = [
    {
        title: 'Adding an account',
        intro: 'The first start opens the account form; File > New Account adds more. Google and Microsoft accounts: one click and a sign-in in the browser. Any other: who you are, then the servers and the password.',
        features: [
            {
                shot: 'account-1-form',
                name: 'Step 1: Sign in with Google or Microsoft, or name and address',
                what: "Google's and Microsoft's own sign-in buttons, unchanged as their branding asks: one click opens their page in the browser, and the account added is the one signed in to (read from the sign-in's OpenID Connect ID token), named as at the provider unless a name was typed. Any other account: a name and an address, nothing technical and no password yet; the servers are looked up from the address after Next.",
                how: 'First start, or File > New Account.',
                checked: [
                    'The form opens on the first start',
                    'It starts with the Google and Microsoft sign-in buttons',
                    'And asks no password before the servers are known'
                ]
            },
            {
                shot: 'account-3-servers',
                name: 'Step 2: the password and the servers, looked up',
                what: "Inbox Classic looks up the provider's settings the way Thunderbird does: the provider's own autoconfig file, then Mozilla's ISPDB, then the usual imap. and smtp. names. Only over HTTPS, and it never picks a server without encryption. The password is asked here, next to the servers it goes to, and the form starts in it.",
                how: 'Follows step 1 automatically. Cancel on the lookup skips it.',
                checked: [
                    'The lookup runs and fills in the guessed names (imap.inboxclassic.test for the test address)',
                    'The server form keeps the name typed first'
                ]
            },
            {
                shot: 'account-6-gmail',
                name: 'Providers recognized by their mail servers',
                what: "The lookup works like EmailEngine's: the servers that receive the domain's mail (MX) are checked against a table of hosted providers (Google Workspace, Microsoft 365, Zoho, AWS WorkMail, Yandex and more), then the domain's SRV records, the provider's settings file, Thunderbird's database and Microsoft Autodiscover race, and the first answer wins. DNS questions go over DNS-over-HTTPS, so nobody on the network can hand out other servers. The form says where the settings came from.",
                how: 'Automatic in step 2.',
                checked: ['A Gmail address gets imap.gmail.com and smtp.gmail.com, found by its MX']
            },
            {
                shot: 'account-5b-browser-sign-in',
                name: 'A Google or Microsoft address typed: their sign-in offered',
                what: "An address found at Google (Gmail, Google Workspace) or Microsoft (Outlook.com, Microsoft 365) is offered that provider's sign-in button when its built-in client is turned on (OAuth 2.0 with PKCE and a loopback redirect), with More sign-in options when sign-in apps are: the password and any second step are typed on their page, never into Inbox Classic, and the account then signs in with tokens kept in the Windows Credential Manager. Use App Password goes the password way instead. With nothing to sign in with, the page is left out. A Microsoft 365 organization that has not approved the app is reported as that, with the address where its administrator approves it.",
                how: 'Type the address and click Next; the button follows the lookup.',
                checked: [
                    'With Google turned off (out of the box), a Gmail address goes to the app password way',
                    'Once turned on, a Gmail address is offered Sign in with Google'
                ]
            },
            {
                shot: 'account-5-app-password',
                name: 'App passwords explained',
                what: "Gmail, iCloud, Yahoo, AOL and T-Online do not take the normal password from mail programs. Inbox Classic says so before the server form and offers to open the provider's own instructions. For Outlook.com and Microsoft 365 it shows Microsoft's note that password sign-in is off.",
                how: 'Shown after the lookup when the provider needs one.',
                checked: ['The note appears for a Gmail address']
            },
            {
                shot: 'account-4-warning',
                name: 'Warning before an unencrypted connection',
                what: 'Choosing "None (unencrypted)" for either server asks for confirmation first, since the password would travel readable. STARTTLS is required to really encrypt; a server that does not offer it is refused.',
                how: 'Shown when a server is set to None.',
                checked: ['The warning appears']
            }
        ]
    },
    {
        title: 'Sign-in apps',
        intro: 'Signing in through the browser uses an OAuth client registered with the provider. Inbox Classic has its own for Google and Microsoft; an OAuth client of your own, at Google, Microsoft or any OpenID Connect provider, is a sign-in app. Each can be turned on or off for new accounts. The UI test signs in for real against the OpenID Connect provider of ImapKit.',
        features: [
            {
                shot: 'signin-1-apps',
                name: 'Sign-in Apps',
                what: 'The built-in Google and Microsoft clients and the added sign-in apps, each with a check box: checked is offered for new accounts. Out of the box Microsoft is on and Google off, since Google lets only test users sign in with Inbox Classic until it verifies the app. Turning one off never cuts an account off: the accounts that use it keep working. The note under the list says what the selected one is; a built-in client can only be turned on or off.',
                how: 'File > Accounts > Sign-in Apps.',
                checked: ['The built-in clients are listed, Microsoft on and Google off', 'A built-in client can not be edited or removed']
            },
            {
                shot: 'signin-4-editor',
                name: 'Adding a sign-in app',
                what: "One form for every provider: name, issuer, client ID, client secret (kept in the Windows Credential Manager, never shown again), scopes and the IMAP and SMTP servers (always encrypted, the token goes to them). Fill in for Google or Microsoft fills in all but the client. The box at the bottom says how to register a client there and the redirect URI to register, with Copy. OK reads the issuer's OpenID Connect discovery document before saving.",
                how: 'Sign-in Apps > Add, or Add a sign-in app in More sign-in options.',
                checked: ['Fill in for Google fills in its issuer, servers and redirect URI', 'The redirect URI follows the issuer', 'OK saves it, turned on']
            },
            {
                shot: 'signin-3-check',
                name: 'Check',
                what: "Reads the issuer's discovery document and says where its sign-in page and token endpoint are, or why the issuer can not be used: not https, a document for another issuer, no PKCE.",
                how: 'Check in the sign-in app editor.',
                checked: ["Check reads the issuer's discovery document"]
            },
            {
                shot: 'signin-6-first-page',
                name: 'A turned-off client on the first page',
                what: 'A branded button whose built-in client is off is faded and can not be clicked, with the reason under it: "Turned off on this computer. Why?". The same words are its tooltip and what a screen reader says. With both off, the buttons are left out.',
                how: 'File > New Account.',
                checked: [
                    'Sign in with Google is shown turned off, Sign in with Microsoft works',
                    'The reason is under it, without hovering',
                    'Once turned on, Sign in with Google works'
                ]
            },
            {
                shot: 'signin-7-why',
                name: 'Why?',
                what: 'Says why the built-in client may be off and what to do instead.',
                how: 'Why? under a faded button.',
                checked: ['Why? says why it is off']
            },
            {
                shot: 'signin-8-more',
                name: 'More sign-in options',
                what: 'A menu of the sign-in apps that are turned on, and Add a sign-in app. The address typed goes to the provider as the account to sign in to.',
                how: 'More sign-in options on the first page of File > New Account.',
                checked: ['It lists the sign-in app and Add a sign-in app', 'A sign-in app turned off is left out']
            },
            {
                shot: 'signin-10-added',
                name: 'Signed in with a sign-in app',
                what: "The browser opens the provider's page; once it comes back the account signed in to is added (its address and name from the ID token) at the sign-in app's servers, and IMAP and SMTP log in with its access token, made again from the refresh token when it runs out. A redirect that names another issuer (RFC 9207) is refused. When the mail server refuses the token, the error says to check the app's scopes.",
                how: 'Choose the app in More sign-in options.',
                checked: [
                    "Signing in opens the sign-in app's page for the address typed",
                    'The provider sends the browser back and the app says it is signed in',
                    'The account is added and its folders sync with the token'
                ]
            },
            {
                shot: 'signin-11-in-use',
                name: 'An app in use stays',
                what: 'A sign-in app that accounts sign in with can not be removed; the message names them. Its check box still turns it off for new accounts.',
                how: 'Sign-in Apps > Remove.',
                checked: ['Removing it is refused, naming the account', 'Space turns apps on and off']
            },
            {
                shot: 'signin-13-properties',
                name: 'What an account signs in with',
                what: "Properties of an account that signs in through the browser names its sign-in app; only its name can change, its servers are the sign-in's.",
                how: 'File > Accounts > Properties.',
                checked: ['Properties says what the account signs in with']
            }
        ]
    },
    {
        title: 'The main window',
        intro: 'Outlook Express layout: folders on the left, the message list at the top, the message below. Classic Windows controls.',
        features: [
            {
                shot: 'main-1-inbox',
                name: 'Folders and the message list',
                what: 'Laid out as Outlook Express: each account with its folders, each with its icon (Inbox, Sent Items, Drafts, Archive, Junk E-mail, Deleted Items), folders with unread mail bold with the count. The grey folder bar and the title name the selected folder. In the list a closed envelope marks unread mail (also bold), an open one read mail, with columns for the paper clip and the flag. Click a column heading to sort, again to reverse. With nothing selected the reading pane says so. The toolbar has the Fluent icons over their labels, in groups.',
                how: 'Always there. Drag the borders between the parts to resize them.',
                checked: ['All 7 folders of the account appear', 'The messages are listed', 'The title names the folder']
            },
            {
                shot: 'all-inboxes-1-list',
                name: 'All Inboxes',
                what: "With two or more accounts, All Inboxes at the top of the folder tree lists the mail of every account's Inbox in one list, newest first, with an Account column naming the account of each message and the unread count of all of them. The app opens on it, with the newest message selected. Reply, Forward, Move and Delete act on the message in its own account, and Create Mail starts from the account of the selected message. Mark All Read on it marks every Inbox read. It goes when only one account is left.",
                how: 'Select All Inboxes at the top of the folder tree.',
                checked: [
                    'It is at the top of the tree, above the accounts',
                    "It lists the mail of both accounts' Inboxes, newest first, with the Account column naming each",
                    'The status bar counts both Inboxes',
                    'A reply goes from the account of the message',
                    'Mark All Read marks both Inboxes read on the servers'
                ]
            },
            {
                shot: 'all-inboxes-2-menu',
                name: "All Inboxes' menu",
                what: 'A right-click on All Inboxes offers Mark All Read, which marks every Inbox read; the folder commands (New Folder, Rename, Delete) are left out, as All Inboxes is no folder of one account.',
                how: 'Right-click All Inboxes in the folder tree.',
                checked: ['The menu has Mark All Read alone']
            },
            {
                shot: 'accounts-1-list',
                name: 'Accounts: change and remove',
                what: "File > Accounts lists the accounts with their address and incoming server. Properties (or a double-click) changes one (leave the password empty to keep it; an account that signs in through the browser only has its name changed, its servers are the provider's). Remove (or Delete) takes it out with its downloaded mail and saved password; the mail on the server stays.",
                how: 'File > Accounts; double click an account for its Properties.',
                checked: [
                    'Both accounts are listed',
                    'Properties shows the saved settings and saves a new name',
                    'Remove asks, removes it, and it leaves the folder tree'
                ]
            },
            {
                shot: 'find-1-results',
                name: 'Search',
                what: 'The search field at the right of the toolbar finds messages in every folder of every account by the words of their subject, people, file names and text, as you type, from a full-text index on this computer (SQLite FTS5): words match where they start, accents and case do not matter. The results are one list with a Folder column. The text of every message is fetched for the index in the background, only its text part, without marking it read. A click anywhere in the field starts typing; Esc, the × at its end, emptying it or choosing a folder shows the folder again.',
                how: 'The search field at the right of the toolbar, Edit > Find Message, or Ctrl+Shift+F.',
                checked: [
                    'A click anywhere in the search field gives it the focus',
                    'A subject word finds that message only',
                    'It searches every folder, with a Folder column',
                    'A sender address is found',
                    'A yellow bar over the list says what was found for which words, the folder bar where',
                    'Clear search on it ends the search',
                    'Clearing it, or its × button, shows the folder again',
                    'Words of the text are found, once the background indexing read them'
                ]
            },
            {
                shot: 'find-3-no-results',
                name: 'No results',
                what: 'When nothing matches, the search bar says "No results for" the words, and the list says so in its middle, with what the search looks at and what to try. While the text of some messages is still being indexed, both say how many, as more may be found soon. An empty folder says "There are no items in this view."',
                how: 'Search for something no message has.',
                checked: ['Nothing is listed for what nothing has', 'The search bar says there are no results']
            },
            {
                shot: 'find-2-every-folder',
                name: 'Gmail search syntax',
                what: 'The search takes Gmail\'s syntax: "phrases", -word, OR, from:, to:, subject:, filename:, is:unread, is:read, is:starred, is:answered, has:attachment, in:inbox or in: and a folder name, before:, after:, older_than:, newer_than:, larger: and smaller: (the field\'s tooltip lists them). Results from other folders open, and Reply, Delete, Move and Flag work on them, in their own folder.',
                how: 'Type the operators in the search field.',
                checked: [
                    'from: finds by sender',
                    'Messages of other folders are found, in:inbox narrows them to the Inbox',
                    'is:unread lists the unread messages',
                    'A result from another folder is shown in the reading pane',
                    'Esc ends the search, without the Folder column'
                ]
            },
            {
                shot: 'tray-2-taskbar',
                name: 'The tray and new mail notifications',
                what: "The Inbox of each account is watched (IMAP IDLE), so new mail comes in as it arrives. Closing the window keeps the app in the notification area, still checking mail; the icon's tooltip and a count on the taskbar button say how many messages are unread in the Inboxes. New unread mail shows a Windows notification while the window is not in front; a click opens the message. Tools > Notify of New Mail turns them off.",
                how: 'Close the window; click the tray icon to open it again, right-click it for Check for New Mail and Exit. File > Exit ends the app.',
                checked: [
                    'The app has its icon in the notification area',
                    'Closing the window hides it in the tray, and the app keeps running',
                    'New mail comes in without a sync while it is hidden',
                    'A click on the icon shows the window again'
                ]
            },
            {
                shot: 'main-2-new-mail',
                name: 'Send/Recv (F5) and automatic checks',
                what: 'Every account is checked at start and every ten minutes; Send/Recv or F5 checks now. The arrow beside Send/Recv checks one account; the one beside Create Mail starts a message from a chosen account. New mail appears in the list without restarting.',
                how: 'Send/Recv on the toolbar (or its arrow), Tools > Send and Receive All, or F5.',
                checked: ['A message added on the server appears after Send/Recv']
            },
            {
                shot: 'main-3-sent-items',
                name: 'Sent Items',
                what: 'A copy of everything sent is kept in the Sent folder on the server, so other mail programs see it too.',
                how: 'Select Sent Items in the folder tree.',
                checked: ['Sent Items lists the reply and the new message']
            }
        ]
    },
    {
        title: 'Reading mail',
        intro: 'Messages are parsed in Rust and shown in a locked-down WebView2: scripts never run, nothing is loaded from the internet unless you ask, links open in your browser.',
        features: [
            {
                shot: 'read-7-properties',
                name: 'Message Properties',
                what: 'The Internet headers of the message, as the Details tab of Outlook Express shows them: who sent it through which servers, its IDs and dates. Shown as text, to read and copy.',
                how: 'File > Properties, or Alt+Enter.',
                checked: ['The headers are shown, without the body', 'OK closes it']
            },
            {
                shot: 'read-14-menu',
                name: 'The message right-click menu',
                what: 'Right-click a message for what can be done with it, as in Outlook Express: reply, forward, mark it read or unread, flag it, junk it, move it, delete it, save or print it, and see its source or properties. The menu fits the message: Mark as Unread for a read one, Not Junk in Junk E-mail, Open for a draft.',
                how: 'Right-click a message in the list, or press the menu key (Shift+F10) on the selected one.',
                checked: ["The menu has the message's actions", 'A read message offers Mark as Unread, not Mark as Read']
            },
            {
                shot: 'read-15-source',
                name: 'View Source',
                what: 'The whole message as the server keeps it (RFC 822): every header, every part, attachments as their encoded text. Shown as plain text in a window that can be made larger, with control characters made harmless; a message over 4 MB is cut short with a note. Save As in the window saves the whole message as an .eml file, as File > Save As does.',
                how: 'View > Message Source (Ctrl+U on Windows and Linux), or View Source on the right-click menu.',
                checked: ['It shows the header and every part', 'The window names the message', 'Save As in it saves the message', 'Close closes it']
            },
            {
                shot: 'read-1-html',
                name: 'HTML messages, with pictures sent inside them',
                what: 'HTML mail is cleaned (no scripts, no forms, no tracking) and shown with its layout. Pictures that travel inside the message are shown at once. Showing a message for a second marks it read, on the server too.',
                how: 'Click a message, or move through the list with the arrow keys.',
                checked: [
                    'Showing the message sets \\Seen on the server',
                    'The Attachments button appears and counts the file',
                    'The Download pictures button appears'
                ]
            },
            {
                shot: 'read-6-folded',
                name: 'Earlier messages folded away',
                what: 'A reply usually carries the messages before it. They fold behind a ••• button under what the sender wrote, so the new part is what you see; click to open them. Which part is history is decided by a Rust port of email-content: only what is clearly an earlier message or a forward is folded, anything uncertain stays in view.',
                how: 'Automatic; click ••• to see the earlier messages.',
                checked: ['A Gmail-style reply shows the new text with the quote folded']
            },
            {
                shot: 'read-2-pictures',
                name: 'Pictures from the internet, only when asked',
                what: 'Pictures the sender keeps on the internet would tell the sender that, when and where you opened the message, so they are blocked. As in Outlook Express, a yellow bar across the message says so when the message has such pictures; a click on it shows them for this message.',
                how: 'Click the yellow bar over the message, or View > Download Pictures.',
                checked: ['The bar appears for a message with such pictures, not for others', 'A click shows the pictures and the bar goes away']
            },
            {
                shot: 'read-13-downloading',
                name: 'Messages being downloaded',
                what: 'A message is downloaded when it is opened, on a connection of its own, so it does not wait behind a long sync of a new account. Its header shows at once from the list; should the message take longer than a moment, the pane says it is being downloaded.',
                how: 'Select a message that was not downloaded yet.',
                checked: ["The header shows the message's sender and subject at once", 'The pane says the message is being downloaded']
            },
            {
                shot: 'read-12-not-downloaded',
                name: 'Messages that could not be downloaded',
                what: 'When the server can not be reached, the pane says why in words (the server, the sign-in or a secure connection), and a bar offers to try again. The message is tried again by itself once the account syncs.',
                how: 'Click the bar (Try Again on the Mac and Linux), or wait for the account to be back online.',
                checked: ['A message that can not be downloaded says why, with Try Again', 'Once the account is back the message shows by itself']
            },
            {
                shot: 'read-3-attachments',
                name: 'Attachments',
                what: 'The paper clip at the right of the header, with how many files there are, lists them with their sizes; Save Attachments saves them all into a folder, a file already there kept and the new one numbered. Files are saved, never opened from here. Names are made safe in Rust: no folder parts, no characters Windows forbids, nothing that makes a name look like something else.',
                how: 'The paper clip button at the right of the message header.',
                checked: ['The menu offers the file']
            },
            {
                shot: 'read-4-save',
                name: 'Saving an attachment',
                what: 'The standard Save dialog, suggesting the safe name, starting in Downloads (after that, where you saved last).',
                how: 'Choose a file in the paper clip menu.',
                checked: ["The suggested name is the attachment's", 'The saved file is byte for byte what was sent']
            },
            {
                shot: 'read-5-unread',
                name: 'Mark Read and Mark Unread',
                what: 'Changes the read state on the server, so other mail programs agree.',
                how: 'Mark Read / Mark Unread on the toolbar, the Edit menu, or Ctrl+Q for read.',
                checked: ['Mark Unread removes \\Seen on the server', 'Mark Read sets it again']
            }
        ]
    },
    {
        title: 'Organizing mail',
        intro: 'What is done to a message is done on the server too, so webmail and your other mail programs agree.',
        features: [
            {
                shot: 'organize-1-flagged',
                name: 'Flag Message',
                what: 'Flags a message (! in the list) or takes the flag away.',
                how: 'Message > Flag Message.',
                checked: ['The server has \\Flagged on it']
            },
            {
                shot: 'organize-2-move',
                name: 'Move to Folder',
                what: 'Moves the selected message to another folder of the account. The next message is selected, as in Outlook Express.',
                how: 'Edit > Move to Folder, or Ctrl+Shift+V.',
                checked: ['The message is in Archive on the server', 'and out of the list']
            },
            {
                shot: 'organize-3-after',
                name: 'Delete',
                what: 'Moves the message to Deleted Items; deleting it there removes it for good. Works on servers without the IMAP MOVE and UIDPLUS extensions too.',
                how: 'Delete on the toolbar, Edit > Delete Message, or the Del key in the list.',
                checked: ['The message is in Deleted Items on the server', 'and out of the Inbox and the list']
            },
            {
                shot: 'read-11-logo',
                name: 'Brand logos (BIMI)',
                what: "The logo of a sender's brand beside the header, when the receiving server's Authentication-Results say bimi=pass and dmarc=pass: from BIMI-Indicator, or fetched once a run from the https BIMI-Location. The SVG is checked (at most 32 KB, no scripts, nothing loaded from elsewhere) and drawn to pixels in Rust (resvg, without text or system fonts).",
                how: 'Select a message from a brand whose logo the server passed.',
                checked: ['A sender whose logo the server passed has it beside the header']
            },
            {
                shot: 'read-10-invitation',
                name: 'Calendar invitations',
                what: "A message with a calendar part (iCalendar, read in Rust) shows its first event over the text: invitation, update or cancellation, the title, when in the reader's time zone (the time zones the file defines, with their daylight-saving rules), where, the organizer, how it repeats and how many attend. Open in Calendar writes the calendar part alone to a file and opens it in the calendar program.",
                how: 'Select a message with an invitation; Open in Calendar on its bar.',
                checked: ['A message with an invitation shows the event over the text, with Open in Calendar']
            },
            {
                shot: 'read-8-unsubscribe',
                name: 'Unsubscribe',
                what: 'A message with List-Unsubscribe has Unsubscribe in its header. With List-Unsubscribe-Post and a DKIM signature that the receiving server passed and that covers both headers (RFC 8058), it asks the list to stop with a one-click POST, without cookies or redirects; otherwise it writes the message the list wants, or opens its https page. It always asks first, saying which.',
                how: 'Unsubscribe at the right of the message header.',
                checked: [
                    'A message of a mailing list has Unsubscribe in its header',
                    'It asks first, naming where it goes',
                    'Yes posts List-Unsubscribe=One-Click to the list, and the status bar says it is done'
                ]
            },
            {
                shot: 'organize-6-drag',
                name: 'Drag messages onto folders',
                what: 'A message dragged from the list onto a folder of its account moves there; with Ctrl it is copied. The folder under the mouse is highlighted, one held over opens, the tree scrolls at its edges, and Esc cancels. Its own folder, an account and a folder of another account take nothing.',
                how: 'Drag a message from the list onto a folder in the tree.',
                checked: [
                    'A message dragged onto Archive is moved there, out of the Inbox and the list',
                    'With Ctrl it is copied there and stays in the Inbox',
                    'Dropped on its own folder, it stays'
                ]
            },
            {
                shot: 'organize-7-junk',
                name: 'Junk / Not Junk',
                what: "Junk moves a message to Junk E-mail with the $Junk keyword of RFC 9051 (and $NotJunk taken away), so the server's spam filter can learn from it. In Junk E-mail the button is Not Junk, which moves it back to the Inbox with $NotJunk. A folder that does not keep keywords still gets the move.",
                how: 'Junk or Not Junk on the toolbar, Message > Mark as Junk (Ctrl+J) or Mark as Not Junk.',
                checked: [
                    'Junk moves the message to Junk E-mail, with $Junk, out of the Inbox',
                    'In Junk E-mail the toolbar has Not Junk in its place',
                    'Not Junk moves it back to the Inbox, with $NotJunk in place of $Junk'
                ]
            },
            {
                shot: 'organize-5-all-read',
                name: 'Mark All Read',
                what: 'Marks every message of a folder read at once: in the list right away, on the server with one command.',
                how: "Edit > Mark All Read, Ctrl+Shift+A, or Mark All Read on the folder's right-click menu.",
                checked: ['No message of the folder is unread in the list', 'and none on the server']
            },
            {
                shot: 'organize-4-for-good',
                name: 'Deleting for good asks first',
                what: 'From Deleted Items, or on an account that has none, Delete removes a message for good, so it asks first. A move or delete the server does not do (offline, refused) puts the message back where it was.',
                how: 'Delete in Deleted Items.',
                checked: ['The question appears', 'Yes removes the message from the server']
            },
            {
                shot: 'folders-2-tree',
                name: 'Folders: new, rename, delete',
                what: 'Makes a folder in the selected one, or at the top of an account, renames a folder (its subfolders go along) and deletes one with its messages after asking. The Inbox and the special folders stay as they are. Subfolders show under their parent whatever order the server lists them in.',
                how: 'File > Folder, or right click in the folder list.',
                checked: [
                    'New Folder makes Archive/Projects on the server, and it shows under Archive',
                    'Rename renames it on the server',
                    'Delete asks, then deletes it on the server',
                    'Renaming the Inbox is refused with the reason'
                ]
            },
            {
                shot: 'folders-5-collapsed',
                name: 'Unread mail in a collapsed account',
                what: 'A collapsed account, or a collapsed folder with folders in it, is bold with the unread messages of the folders it hides, so new mail is not out of sight. Junk E-mail and Deleted Items do not count. Expanded, each folder shows its own again.',
                how: 'Click the arrow beside an account or a folder to collapse it.',
                checked: ['Collapsed, the account shows the unread messages of its folders, bold', 'Expanded, the count is back on the Inbox alone']
            }
        ]
    },
    {
        title: 'AI agents',
        intro: 'Let the AI agent you already use (Claude, Cursor, any MCP client) read and organize your mail. There is no AI in Inbox Classic: an agent connects only when you let its program in, sees only the accounts you choose, and every message it wants to send waits for your yes. Each change is listed and can be taken back.',
        features: [
            {
                shot: 'agents-1-before',
                name: 'Before: unread mail',
                what: 'Two new messages in the Inbox, unread and bold, before the agent starts.',
                how: 'The agent is started by its own program (Claude Desktop and the like) with Inbox Classic as an MCP server: Tools > AI Agents > How to Connect an Agent.',
                checked: ['Two new unread messages are in the list']
            },
            {
                shot: 'agents-2-connect',
                name: 'A program connects for the first time',
                what: "The first time a program's agent connects, Inbox Classic asks: which program it is (by its file), what it may do (read, organize, write drafts, send with your yes) and which accounts it may see. Reading and organizing are offered; sending is not. Don't Allow is the default, and a program turned away is not asked about again.",
                how: 'Shown when an agent connects; changed later in Tools > AI Agents.',
                checked: [
                    'The question names the program',
                    'Reading and organizing are offered, sending is not',
                    'Allowed, the agent connects with the tools of what it may do'
                ]
            },
            {
                shot: 'agents-3-after',
                name: 'Changes show in the windows at once',
                what: "What the agent changes goes through the same core as the menus: messages it marks read lose their bold at once, and the server has the change. Reading a message does not mark it read, and the agent gets the text a reader sees, without what the message hides (text in white, in display:none), told it is the sender's words, not instructions.",
                how: 'Automatic.',
                checked: [
                    "It reads a message as text, told it is the sender's, without marking it read",
                    'It marks two messages read, on the server and in the window at once'
                ]
            },
            {
                shot: 'agents-4-send',
                name: 'Nothing is sent without your yes',
                what: "A message an agent wants to send is shown in full first: every recipient by address, new addresses marked, the subject and the text. Send comes on after a moment, so a key pressed for another window does not send; Don't Send is the default, and Edit First opens it in a new message to change.",
                how: 'Shown when an agent asks to send; only for a program allowed to send.',
                checked: [
                    'Every recipient by address, the new ones marked, with a warning',
                    'Send waits a moment before it can be pressed',
                    'The agent learns the user said yes'
                ]
            },
            {
                shot: 'agents-5-outbox',
                name: 'Sent messages wait 30 seconds',
                what: 'What you let an agent send waits 30 seconds in the Outbox, where it can still be deleted, or taken back with Undo in Tools > AI Agents.',
                how: 'Tools > Outbox.',
                checked: ['It waits in the Outbox, where it can still be deleted']
            },
            {
                shot: 'agents-6-window',
                name: 'Tools > AI Agents',
                what: "Turn agents off altogether, see the programs let in or turned away and change what each may do, and see everything agents did, newest first, with Undo for read state, flags, moves and deletes, and for a message still in the Outbox. How to Connect an Agent gives the settings to paste into an agent's configuration.",
                how: 'Tools > AI Agents.',
                checked: ['It lists the program and what it may do', 'And what its agent did, newest first', 'Undo takes the message back']
            }
        ]
    },
    {
        title: 'Files and printing',
        features: [
            {
                shot: 'files-1-save-as',
                name: 'Save As (.eml)',
                what: 'Saves the message shown as an .eml file, named after its subject with what Windows does not allow taken out.',
                how: 'File > Save As.',
                checked: ['The Save dialog suggests the subject as the name', 'The file is the message as it came']
            },
            {
                shot: 'files-2-import',
                name: 'Import Messages',
                what: 'Puts .eml files into the selected folder, on the server too. Files that are not messages, or larger than 50 MB, are named and left out.',
                how: 'File > Import Messages.',
                checked: ['The saved message is in Archive on the server']
            },
            {
                shot: 'files-3-print',
                name: 'Print',
                what: 'A window over the app with the print preview of the message shown: the printer (or save as PDF), copies, layout and pages, and a live preview with the sender, date, recipients and subject on top. It closes once printed or cancelled.',
                how: 'File > Print, or Ctrl+P.',
                checked: ['The print preview opens with the header of the message']
            }
        ]
    },
    {
        title: 'Writing mail',
        intro: 'A compose window per message. Sending goes over SMTP from the account the message belongs to; problems are reported before anything is sent.',
        features: [
            {
                shot: 'write-3-reply',
                name: 'Reply, in the HTML editor',
                what: 'Messages are written as formatted text: the bar above the text sets the font and size, bold, italic, underline, color, lists, indent, alignment, links, a dividing line and pictures, and shows what is on at the cursor. A reply has "Re:" in the subject and the original folded behind ••• under the text (sent along in full), threaded with In-Reply-To and References. Spelling is checked; Ctrl+Enter sends. The message goes as HTML with a plain text copy.',
                how: 'Reply on the toolbar, Message > Reply to Sender, or Ctrl+R.',
                checked: ['The reply goes to the sender', 'It arrives over SMTP with In-Reply-To set and the typed text', 'A copy is kept in Sent']
            },
            {
                shot: 'write-2-reply-all',
                name: 'Reply All',
                what: 'Answers the sender and everyone else the message went to, keeping Cc, leaving out your own address.',
                how: 'Reply All on the toolbar, Message > Reply to All, or Ctrl+Shift+R.',
                checked: ['To has the sender and the other recipients, not you', 'Cc is kept']
            },
            {
                shot: 'write-1-forward',
                name: 'Forward',
                what: 'Sends the message on with "Fw:" in the subject and the original shown below, pictures included. The recipients are left to you.',
                how: 'Forward on the toolbar, Message > Forward, or Ctrl+F.',
                checked: ['The subject is "Fw: October newsletter"', 'To is empty']
            },
            {
                shot: 'write-5-new',
                name: 'A new message',
                what: 'From shows the account the message goes from (name and address), and with several accounts chooses another. Cc and Bcc wait behind buttons at the end of the To line until needed. Written in HTML; without any formatting it goes as plain text, and a reply or forward follows the original. To, Cc, Bcc, Subject, the text and attached files (Attach, or dragged from Explorer), listed with their size; Delete or a right-click takes one off. Several addresses are separated with commas; names with commas go in quotes.',
                how: 'Create Mail on the toolbar, Message > New Message, or Ctrl+N.',
                checked: ['From names the account', 'Attach adds the files', 'Delete takes one off', 'The message is sent and arrives with only the file left']
            },
            {
                shot: 'write-13-dropped-picture',
                name: 'Pictures dropped into the text',
                what: 'A picture file dragged from Explorer onto the text goes where it was dropped, as the Picture button puts one: the core checks that it is a PNG, JPEG, GIF or WebP picture of at most 10 MB, and sending carries it inside the message as a cid: part of multipart/related. Any other file dropped there is attached.',
                how: 'Drag picture files from Explorer onto the text of a message.',
                checked: [
                    'The text takes the files dropped on it',
                    'A file that is no picture is attached',
                    'The picture is sent inline as a cid: part, with no data: URI left in the HTML'
                ]
            },
            {
                shot: 'write-14-link-status',
                name: 'Where a link goes',
                what: 'With the cursor in a link, or the mouse over one, the status bar of the message window shows its address, with Ctrl+click to open it in the browser (http, https and mailto only, as in the reading pane).',
                how: 'Put the cursor in a link, or point at it.',
                checked: ['With the cursor in a link, the status bar shows its address']
            },
            {
                shot: 'write-15-edit-link',
                name: 'Changing and removing a link',
                what: 'Link (Ctrl+K) on a link shows its address to change; an empty address takes the link off and keeps its text. On text without a link it makes a new one.',
                how: 'Link on the format bar, or Ctrl+K, with the cursor in a link.',
                checked: ['The Link button on a link shows its address', 'It changes it', 'An empty address removes the link, the text goes without it']
            },
            {
                shot: 'write-16-link-menu',
                name: 'The menu of a link',
                what: "Right-clicking a link selects it and offers Open Link, Edit Link and Remove Link first. The browser's own items that do nothing in a message being written (open in a new window, save link as, print) are left out.",
                how: 'Right-click a link in the text.',
                checked: []
            },
            {
                shot: 'write-3b-select-all',
                name: 'Select All takes the quote',
                what: 'Ctrl+A unfolds the quoted message into the text and selects all of it, to copy or cut; unfolded, the quote can be shortened before sending, and it is sent once.',
                how: 'Ctrl+A in the text, or the ••• button.',
                checked: ['The quote is selected with the text', 'The sent reply has the quote once']
            },
            {
                shot: 'write-7-outbox',
                name: 'The Outbox',
                what: 'Every message goes through the Outbox: one that can not go (offline, refused) waits there with the reason and goes with the next Send/Recv, so nothing is lost. Send/Recv also runs by itself every ten minutes. The middle of the status bar says what happens to what you send (Sending, Sent with its subject and time, or waiting in the Outbox), and other work does not write over it; Tools > Outbox lists each waiting message with when it was queued and why it did not go.',
                how: 'Automatic when a send can not go; Tools > Outbox to send now or delete.',
                checked: [
                    'There is no Send Later: Send sends',
                    'A send that can not go says it waits in the Outbox',
                    'The Outbox lists the message',
                    'Once the server is back it goes by itself'
                ]
            },
            {
                shot: 'write-8-save-draft',
                name: 'Drafts',
                what: 'Save keeps the message in the Drafts folder on the server, in place of the copy saved before, and the status bar of the message says when the server has it (or why not). Closing a message with changes asks: Yes saves it in Drafts, No throws it away, Cancel goes back to it.',
                how: 'Save or Ctrl+S in the compose window, or close it and answer Yes.',
                checked: ['Closing asks to save', 'Yes saves the draft on the server, marked as a draft']
            },
            {
                shot: 'write-9-draft-reopened',
                name: 'Finishing a draft',
                what: 'A draft opens again with its recipients, text and attached files. Sending it removes it from Drafts.',
                how: 'Double-click the draft in Drafts, or select it and press Enter.',
                checked: ['The draft opens with its subject and recipient', 'Save replaces it', 'Sent, it arrives and leaves Drafts']
            },
            {
                shot: 'write-10-draft-saved',
                name: 'Saved, and said so',
                what: 'The status bar of the message window says Saved in Drafts with the time once the server has the draft, Saving to Drafts while it goes, or why it was not saved. Writing more clears it, as the saved copy is then behind.',
                how: 'Save or Ctrl+S in the compose window.',
                checked: ['The message window says when the draft is saved']
            },
            {
                shot: 'write-11-sent',
                name: 'Sent, and said so',
                what: 'Once the server took a message, the middle of the main status bar says Sent with its subject and the time, and stays so until the next message goes; while it goes it says Sending, and a message that can not go is reported as waiting in the Outbox.',
                how: 'Automatic after Send.',
                checked: ['The main window says what was sent']
            },
            {
                shot: 'write-0-main-in-front',
                name: 'Writing in a window of its own',
                what: 'A message being written is a window of its own on the taskbar, as in Outlook Express: the main window comes in front of it to look something up, and the keyboard goes back to where it was. Closing the app closes the messages being written first, asking about those with changes.',
                how: 'Click the main window, or Alt+Tab, while writing.',
                checked: ['The message window is a window of its own', 'The main window comes in front of a message being written']
            },
            {
                shot: 'write-6-close',
                name: 'Nothing written is lost by accident',
                what: 'Closing a message with changes asks whether to save them in Drafts, throw them away or go back.',
                how: 'Close the compose window.',
                checked: ['Closing asks', 'No closes it without saving']
            },
            {
                shot: 'write-4-bad-address',
                name: 'Mistakes are caught before sending',
                what: 'A mistyped address or an attachment that is gone is pointed out, and the message stays open to fix.',
                how: 'Happens on Send.',
                checked: ['"dave at example.com" is refused with the reason', 'The compose window stays open']
            },
            {
                shot: 'write-18-mailto',
                name: 'The default mail app (mailto: links)',
                what: "The installer lists Inbox Classic among the mail programs of Windows; chosen as the default, e-mail links open a new message with the link's addresses, subject and text (RFC 6068), and nothing else of it. A second start of the app hands the link to the one already open.",
                how: 'Tools > Make Default Mail App opens the Default apps settings of Windows; then click an e-mail link.',
                checked: ['A second start with a mailto: link hands it over and ends', "The running app opens a new message from it, to the link's address"]
            },
            {
                shot: 'write-17-complete',
                name: 'Address completion',
                what: 'Typing in To, Cc or Bcc lists the people it may be from an address book on this computer: the recipients of Sent Items and the senders of the rest (Junk left out), those written to most first. Arrows choose, Enter or Tab takes one with a comma for the next, Esc closes the list, Shift+Delete forgets someone for good.',
                how: 'Type a few letters of a name or an address in To, Cc or Bcc.',
                checked: [
                    'Typing in To lists the people it may be, with someone heard from',
                    'Enter takes the first, with a comma for the next, and closes the list'
                ]
            },
            {
                shot: 'signature-1-editor',
                name: 'Signatures',
                what: 'Each account has a signature of its own, written with the formatting of a message and kept sanitized. New messages, replies and forwards start with it, after an empty line and "-- ", above the quote; another account in From swaps it for its own.',
                how: 'File > Accounts, select the account, Signature.',
                checked: ['Signature opens the editor of the account, which takes typing', 'OK saves it']
            },
            {
                shot: 'signature-2-new',
                name: 'A new message starts with the signature',
                what: 'What is written goes above the signature, and a reply has it above the quoted message.',
                how: 'Create Mail, Reply, Reply All or Forward.',
                checked: ['The message went with the signature, after what was written and the "-- " line', 'A reply has the signature above the quote']
            }
        ]
    },
    {
        title: 'When something goes wrong',
        features: [
            {
                shot: 'trouble-1-password',
                name: 'A refused password',
                what: 'The status bar says what the server answered and Inbox Classic asks for the password again (for a browser sign-in account it offers to sign in again). A server that only takes the password over an encrypted connection is reported as that, not as a wrong password.',
                how: 'Happens on its own when a server refuses the login.',
                checked: ['The Logon prompt appears', 'The status bar keeps the reason']
            }
        ]
    },
    {
        title: 'Help',
        features: [
            {
                shot: 'help-2-contents',
                name: 'Help',
                what: 'A help window built into the program: adding accounts (with Gmail and Outlook.com app passwords), reading, pictures and attachments, writing, getting mail, keyboard shortcuts, troubleshooting by error message, and where mail and passwords are kept.',
                how: 'F1 or Help > Contents.',
                checked: ['F1 opens it']
            },
            {
                shot: 'help-1-about',
                name: 'About',
                what: 'The version of the program and of its Rust core.',
                how: 'Help > About Inbox Classic.',
                checked: ['It opens']
            }
        ]
    }
];

const behind = [
    ['Passwords', 'Kept in the Windows Credential Manager (under "Inbox Classic"), encrypted for your Windows account; never in the mail store.'],
    ['Offline reading', 'Messages are cached in %LOCALAPPDATA%\\InboxClassic\\store.db, so what was downloaded can be read without a connection.'],
    [
        'Security model',
        'Everything a server or sender writes is parsed in Rust (IMAP, MIME, HTML sanitizing, attachment names, autoconfig XML). The Windows UI only shows values the core has checked. The reading pane has scripts, remote requests and navigation turned off.'
    ],
    ['Certificates', 'Server certificates are checked against what Windows trusts. There is no "accept any certificate" switch.'],
    [
        'Installer',
        'A per-user installer (no admin rights), signed by Postal Systems OÜ, that upgrades in place and asks on uninstall whether to remove the downloaded mail.'
    ]
];

// the screenshots a platform's UI test does not take yet, each a gap to close; Windows has none
const notYet = {
    windows: [],
    mac: [
        // the system's own file panels and the Dock or the top bar run in processes of their own: their pictures can
        // not be taken from inside the app (the test answers the panels in their place and checks what they did)
        'read-3-attachments',
        'read-4-save',
        // a menu runs in a tracking loop of its own, which a picture taken from inside the app does not see
        'read-14-menu',
        'all-inboxes-2-menu',
        'files-1-save-as',
        'files-2-import',
        'tray-2-taskbar',
        // steps of ui-e2e.ps1 the test does not take yet
        'account-5b-browser-sign-in',
        'signin-3-check',
        'signin-6-first-page',
        'signin-7-why',
        'signin-8-more',
        'signin-10-added',
        'signin-11-in-use',
        'signin-13-properties',
        'organize-6-drag',
        'write-0-main-in-front',
        'write-3b-select-all',
        'write-13-dropped-picture',
        'write-14-link-status',
        'write-15-edit-link',
        'write-16-link-menu'
    ],
    linux: [
        // the system's own file panels and the Dock or the top bar run in processes of their own: their pictures can
        // not be taken from inside the app (the test answers the panels in their place and checks what they did)
        'read-4-save',
        'files-1-save-as',
        'files-2-import',
        'tray-2-taskbar',
        // steps of ui-e2e.ps1 the test does not take yet
        'account-5b-browser-sign-in',
        'signin-4-editor',
        'signin-3-check',
        'signin-6-first-page',
        'signin-7-why',
        'signin-8-more',
        'signin-10-added',
        'signin-11-in-use',
        'signin-13-properties',
        'organize-6-drag',
        'write-0-main-in-front',
        'write-3b-select-all',
        'write-13-dropped-picture',
        'write-14-link-status',
        'write-15-edit-link',
        'write-16-link-menu'
    ]
};
if (checking) {
    if (!notYet[checking]) {
        console.error(`--check takes windows, mac or linux, not ${checking}`);
        process.exit(1);
    }
    const shots = sections.flatMap(section => section.features.map(feature => feature.shot));
    const absent = shots.filter(shot => !existsSync(join(dir, `${shot}.png`)));
    const unexpected = absent.filter(shot => !notYet[checking].includes(shot));
    const closed = notYet[checking].filter(shot => !absent.includes(shot));
    console.log(`${checking}: ${shots.length - absent.length} of ${shots.length} features shown, ${notYet[checking].length} not yet`);
    if (closed.length) {
        console.log(`now shown, take them off notYet.${checking}: ${closed.join(', ')}`);
    }
    if (unexpected.length) {
        console.error(`no screenshot of: ${unexpected.join(', ')}`);
        process.exit(1);
    }
    process.exit(0);
}

const missing = [];

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const image = name => {
    const path = join(dir, `${name}.png`);
    return existsSync(path) ? `data:image/png;base64,${readFileSync(path).toString('base64')}` : null;
};

let count = 0;
const body = sections
    .map(section => {
        const cards = section.features
            .map(feature => {
                count++;
                const src = image(feature.shot);
                const picture = src
                    ? `<a class="shot" href="#${feature.shot}"><img src="${src}" alt="${esc(feature.name)}" loading="lazy"></a>`
                    : `<div class="shot missing">No screenshot (${esc(feature.shot)})</div>`;
                return `<article class="feature" id="f-${feature.shot}">
  <div class="text">
    <h3>${esc(feature.name)}</h3>
    <p>${esc(feature.what)}</p>
    <p class="how"><span>How</span>${esc(feature.how)}</p>
    <div class="checked"><span>Checked by the UI test</span><ul>${feature.checked.map(c => `<li>${esc(c)}</li>`).join('')}</ul></div>
  </div>
  ${picture}
</article>
${src ? `<a class="lightbox" id="${feature.shot}" href="#f-${feature.shot}"><img src="${src}" alt=""></a>` : ''}`;
            })
            .join('\n');
        return `<section><h2>${esc(section.title)}</h2>${section.intro ? `<p class="intro">${esc(section.intro)}</p>` : ''}\n${cards}</section>`;
    })
    .join('\n');

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Inbox Classic Features</title>
<style>
:root { --bg: #f6f5f1; --card: #ffffff; --ink: #1d232b; --muted: #5c6670; --line: #e2dfd7; --accent: #0b4f8a; --ok: #1d7a46; --chip: #eef3f8; }
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { --bg: #15181c; --card: #1d2127; --ink: #e7e9ec; --muted: #9aa4ae; --line: #2c323a; --accent: #7db4ea; --ok: #63c48d; --chip: #222a33; }
}
:root[data-theme="dark"] { --bg: #15181c; --card: #1d2127; --ink: #e7e9ec; --muted: #9aa4ae; --line: #2c323a; --accent: #7db4ea; --ok: #63c48d; --chip: #222a33; }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--ink); font: 15px/1.55 "Segoe UI", system-ui, sans-serif; }
header, main, footer { max-width: 1180px; margin: 0 auto; padding: 0 24px; }
header { padding-top: 48px; padding-bottom: 8px; }
h1 { font-size: 34px; margin: 0 0 6px; letter-spacing: -0.5px; }
.lead { color: var(--muted); font-size: 17px; max-width: 760px; margin: 0; }
nav { display: flex; flex-wrap: wrap; gap: 8px; margin: 22px 0 6px; }
nav a { background: var(--chip); color: var(--accent); text-decoration: none; padding: 4px 12px; border-radius: 999px; font-size: 13px; }
h2 { font-size: 22px; margin: 44px 0 4px; padding-bottom: 6px; border-bottom: 2px solid var(--line); }
.intro { color: var(--muted); margin: 6px 0 16px; max-width: 820px; }
.feature { display: grid; grid-template-columns: minmax(260px, 1fr) minmax(0, 1.6fr); gap: 24px; background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 20px; margin: 14px 0; align-items: start; }
.feature h3 { margin: 0 0 8px; font-size: 17px; }
.feature p { margin: 0 0 10px; }
.how span, .checked > span { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; color: var(--muted); margin-bottom: 2px; }
.checked ul { margin: 0; padding: 0; list-style: none; }
.checked li { padding-left: 20px; position: relative; font-size: 14px; }
.checked li::before { content: "\\2713"; position: absolute; left: 0; color: var(--ok); font-weight: 700; }
.shot img { width: 100%; height: auto; display: block; border: 1px solid var(--line); border-radius: 6px; cursor: zoom-in; }
.shot.missing { color: var(--muted); font-style: italic; }
.lightbox { display: none; }
.lightbox:target { display: flex; position: fixed; inset: 0; background: rgba(0,0,0,0.82); align-items: center; justify-content: center; z-index: 10; cursor: zoom-out; padding: 24px; }
.lightbox img { max-width: 100%; max-height: 100%; border-radius: 4px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 14px; }
.grid div { background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 14px 16px; }
.grid b { display: block; margin-bottom: 4px; }
ul.missing { background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 14px 16px 14px 36px; margin: 12px 0; }
ul.missing li { margin: 3px 0; }
footer { color: var(--muted); font-size: 13px; padding-top: 30px; padding-bottom: 48px; }
@media (max-width: 760px) { .feature { grid-template-columns: 1fr; } header { padding-top: 28px; } h1 { font-size: 28px; } header, main, footer { padding: 0 16px; } }
</style>
</head>
<body>
<header>
<h1>Inbox Classic ${esc(version)}: what it can do</h1>
<p class="lead">Every feature of the app, with a screenshot of it running. The screenshots come from the UI end-to-end test, which drives the real program against a test mail server and checks each effect on the server. Click a screenshot to enlarge it.</p>
<nav>${sections.map((s, i) => `<a href="#s${i}">${esc(s.title)}</a>`).join('')}<a href="#behind">Behind the scenes</a>${missing.length ? '<a href="#missing">Not there yet</a>' : ''}</nav>
</header>
<main>
${body.replace(
    /<section>/g,
    (() => {
        let i = 0;
        return () => `<section id="s${i++}">`;
    })()
)}
<section id="behind"><h2>Behind the scenes</h2><div class="grid">${behind.map(([t, d]) => `<div><b>${esc(t)}</b>${esc(d)}</div>`).join('')}</div></section>
${missing.length ? `<section id="missing"><h2>Not there yet</h2><p class="intro">What an Outlook Express user would look for and does not find yet.</p><ul class="missing">${missing.map(m => `<li>${esc(m)}</li>`).join('')}</ul></section>` : ''}
</main>
<footer>${count} features. Generated ${new Date().toISOString().slice(0, 10)} by scripts/feature-map.mjs from the screenshots of scripts/ui-e2e.ps1.</footer>
</body>
</html>
`;
writeFileSync(out, html);
console.log(`${out}: ${count} features`);
