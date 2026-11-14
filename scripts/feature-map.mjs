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
                what: 'Laid out as Outlook Express: each account with its folders, each with its icon (Inbox, Sent Items, Drafts, Archive, Junk E-mail, Deleted Items), folders with unread mail bold with the count. The grey folder bar and the title name the selected folder. In the list unread mail is bold, with columns for the paper clip and the flag. Click a column heading to sort, again to reverse. With nothing selected the reading pane says so. The toolbar has the Fluent icons over their labels, in groups.',
                how: 'Always there. Drag the borders between the parts to resize them.',
                checked: ['All 7 folders of the account appear', 'The messages are listed', 'The title names the folder']
            },
            {
                shot: 'main-10-flagged',
                name: 'Flagged',
                what: 'One row lists the flagged messages of every account and folder, with the Folder each is in and how many there are; not those in Deleted Items or Junk E-mail, and on Gmail each once.',
                how: 'The Flagged row in the folder list.',
                checked: ['Flagging a message counts it', 'Flagged lists the flagged messages of every folder', 'Unflagged, it is no longer counted']
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
                shot: 'all-inboxes-3-accounts',
                name: 'All Inboxes by account',
                what: "Under All Inboxes each account's Inbox has a row of its own, named as the account is, with its unread count: the same Inbox the account's own section has, a second way to it. All Inboxes lists every Inbox's mail; a row under it lists that Inbox alone, and the folder bar names the Inbox and the account. The folder list remembers which rows were open. Each account has an Account name of its own (Gmail, Work), set in its Properties; a new one starts with its provider's name or its domain.",
                how: "Open All Inboxes in the folder tree and select an account's row under it; File > Accounts > Properties for the Account name.",
                checked: [
                    'All Inboxes has a row for each account, with its unread count',
                    "An account's row lists its Inbox alone, the folder bar names it",
                    "The Account name set in Properties is the account's heading and its row's name"
                ]
            },
            {
                shot: 'account-menu',
                name: "The account's menu",
                what: "A right-click on an account in the folder tree offers Send and Receive (that account's server alone), Mark All Read (every folder of the account), New Folder and Properties.",
                how: 'Right-click an account in the folder tree.',
                checked: [
                    'The menu has Send and Receive, Mark All Read, New Folder and Properties',
                    "Mark All Read marks the account's folders read on its server, not the other account's"
                ]
            },
            {
                shot: 'all-inboxes-4-reorder',
                name: 'Reorder accounts',
                what: "The accounts have an order of your own: drag an account, or its Inbox under All Inboxes, above or below another, and a line shows where it lands. The rows under All Inboxes and the accounts' folders below follow the same order. Move Up and Move Down on the account's menu do the same from the keyboard.",
                how: 'Drag an account or its row under All Inboxes; or right-click it and choose Move Up or Move Down.',
                checked: [
                    'Moving the second account first puts it first under All Inboxes and in the folder tree',
                    "Move Down on the account's menu puts it back"
                ]
            },
            {
                shot: 'move-1-dialog',
                name: 'Move and Copy to Folder',
                what: 'Move to Folder and Copy to Folder show the folders of every account in a tree, with a filter box at the top (type part of a name to narrow it), the last folders used under Recent, and New Folder. The folder the messages are in is shown but can not be chosen, and the button says what it does: Move or Copy.',
                how: 'Edit > Move to Folder (Ctrl+Shift+V) or Edit > Copy to Folder, or the message menu.',
                checked: [
                    'The folders of both accounts are in the tree, with a filter box',
                    'The folder the message is in can not be chosen, and the button says Move',
                    'The filter narrows the tree; the folder used last is under Recent'
                ]
            },
            {
                shot: 'move-2-accounts',
                name: 'Moving between accounts',
                what: "Messages move or copy to a folder of another account through the dialog or by dragging them onto it. The message is copied to the other account's server first, with its flags and date, and only then removed from its own, so nothing is lost when the connection drops or the app quits on the way; it goes on with the next sync. The status bar says how far it is, and Edit > Undo moves it back.",
                how: 'Move to Folder or Copy to Folder and a folder of another account, or drag messages onto one (Ctrl, Option on the Mac, copies).',
                checked: [
                    "A message moved to the second account's Archive is there on its server, with its flags, and gone from the first",
                    'Undo brings it back to the first account',
                    'Copy keeps it in the Inbox; a drag onto the other account moves it'
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
                shot: 'tray-3-badge',
                name: 'The unread count on the taskbar',
                what: "The taskbar button carries the number of unread messages in the Inboxes as a small red badge (99+ past 99), gone when there are none, as the Mac's Dock and Linux docks show it.",
                how: 'It is there by itself while the app runs.',
                checked: ['The taskbar button shows the unread count']
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
                what: 'A copy of everything sent is kept in the Sent folder on the server, so other mail programs see it too. Sent Items and Drafts name whom each message went to, in a To column, instead of the sender.',
                how: 'Select Sent Items in the folder tree.',
                checked: ['Sent Items lists the reply and the new message', 'Its person column is To, with the recipients']
            }
        ]
    },
    {
        title: 'Reading mail',
        intro: 'Messages are parsed in Rust and shown in a locked-down WebView2: scripts never run, nothing is loaded from the internet unless you ask, links open in your browser.',
        features: [
            {
                shot: 'read-30-text-size',
                name: 'Text Size',
                what: 'View > Text Size shows messages, and the text being written, Largest to Smallest, as Outlook Express did; the size in use is checked and kept. It has no keys, and the web views\' own zoom is off, so it never changes by accident.',
                how: 'View > Text Size.',
                checked: ['Medium at first', 'Larger shows the message larger', 'Medium again']
            },
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
                shot: 'pictures-2-trusted',
                name: 'Pictures from trusted senders',
                what: "The pictures bar's menu offers to always download pictures from the sender, or from everyone at their domain. They then load by themselves, but only when the account's provider confirms the message comes from that domain (DKIM or DMARC in its Authentication-Results), so a forged sender still asks and says why. Nothing loads by itself in Junk E-mail.",
                how: 'The arrow beside Download Pictures in the pictures bar.',
                checked: [
                    'A confirmed sender is offered Always from the address and from the domain',
                    'A forged one is told it could not be confirmed',
                    "Trusted, the confirmed one's pictures load without the bar; the forged one still asks"
                ]
            },
            {
                shot: 'pictures-3-options',
                name: 'Trusted senders and pictures in every message',
                what: 'Options lists the trusted senders with Remove, and has "Download pictures in all messages", off out of the box, with what it tells senders.',
                how: 'Options (Settings on the Mac, Preferences on Linux), the reading part.',
                checked: ['The trusted sender is listed and can be removed', "With the setting on, every message's pictures load"]
            },
            {
                shot: 'open-1-from-store',
                name: 'A message downloaded ahead opens at once',
                what: 'New mail is downloaded as it arrives, so opening it shows it from this computer at once, with no download. While a message is downloaded, the pane says how large it is.',
                how: 'Open a message that came in since the app started.',
                checked: ['A new message is downloaded before it is opened', 'It opens from the store, without a download']
            },
            {
                shot: 'large-1-text-first',
                name: 'Large messages show their text first',
                what: 'A message over 1 MB shows its text and the pictures in it first, fetched by part, with its attachments listed; the rest follows in the background, and the status bar says how far it is. Its attachments, Save As, View Source and Forward wait until it is all here.',
                how: 'Open a large message.',
                checked: ['The text is shown before the rest is here', 'The status bar says how far it is, then that it is all here']
            },
            {
                shot: 'download-1-options',
                name: 'Messages downloaded before they are opened',
                what: 'New mail is downloaded as it arrives, so it opens at once, and the messages above and below the one opened are fetched for Next and Previous. Options says what is downloaded ahead (recent messages up to 1 MB out of the box, all of them, or only when opened) and how much each account keeps; past it, the oldest are removed and downloaded again when opened. Junk E-mail, Deleted Items and Gmail’s All Mail are downloaded only when opened.',
                how: 'Options (Settings on the Mac, Preferences on Linux), the downloading part.',
                checked: ['What is downloaded ahead and 1 GB kept for each account are shown', 'A choice is kept']
            },
            {
                shot: 'list-unread-only',
                name: 'Unread only',
                what: "The list's unread messages only, in every folder, remembered: View > Hide Read Messages, or the toolbar's filter button. A message read stays listed until you go to another folder, so it does not vanish while you read it.",
                how: 'View > Hide Read Messages, or the filter button in the toolbar.',
                checked: ['Only the unread messages are listed', 'One read stays until the folder changes', 'Turned off, every message is back']
            },
            {
                shot: 'layout-1-columns',
                name: 'The column layout',
                what: 'Folders, messages and the message side by side, for a wide screen. Each message is a row of three lines: who and when, the subject with its marks, and the first words the sender wrote (without the quoted reply). Classic stays as it was.',
                how: 'View > Layout > Columns, or the same choice in Options (Settings on the Mac, Preferences on Linux).',
                checked: ['The list stands beside the reading pane', 'Rows of three lines with the first words', 'Back to Classic as before']
            },
            {
                shot: 'layout-2-automatic',
                name: 'The layout chosen by the width',
                what: 'Automatic, the default: a window 1320 wide or wider shows the column layout, one narrower than 1200 the classic one, and in between it keeps what it has, so dragging the edge does not make it flicker. The first time, the status bar says where to change it.',
                how: 'View > Layout > Automatic, then make the window wider or narrower.',
                checked: ['Wide: Columns', 'Narrow: Classic', 'The status bar says so once']
            },
            {
                shot: 'layout-4-sort',
                name: 'Sort By',
                what: 'View > Sort By orders the list by date, sender, subject or size, ascending or descending, in both layouts. The column layout has no column headings: the Sorted by button above the list opens the same choices.',
                how: 'View > Sort By, the Sorted by button in the column layout, or a column heading in the classic one.',
                checked: ['The order changes', 'The button says what the list is sorted by']
            },
            {
                shot: 'pictures-4-list',
                name: "Senders' pictures in the message list",
                what: "In the column layout each row has the sender's picture: the brand's logo when the mail provider confirmed it, else the sender's initials on a quiet fill. A logo is downloaded once for each brand, never for each message, so no sender learns who opened what.",
                how: "The column layout (View > Layout > Columns). Options turns them off: Show senders' pictures in the message list.",
                checked: ['A confirmed logo in its row', 'Initials for the rest', 'The setting turns them off']
            },
            {
                shot: 'pictures-5-contact',
                name: "Contacts' pictures in the list and the reading pane",
                what: "Mail from a contact with a picture shows it in the column layout's row and beside the message, when the provider confirmed the sender's domain.",
                how: 'Give a contact a picture in the Address Book; the column layout shows it.',
                checked: ['In the row', 'In the reading pane']
            },
            {
                shot: 'layout-5-conversation',
                name: 'Conversations in the column layout',
                what: 'A conversation is one row with its count; opened, its messages follow it, indented.',
                how: 'Click the count at the right of a conversation, or press Right and Left.',
                checked: ['A conversation opens and closes', 'Its messages are indented']
            },
            {
                shot: 'layout-3-folders-hidden',
                name: 'Hiding the folder list',
                what: 'More room for the messages: View > Folder List (F9, Control-Command-S on the Mac) hides the folder list and brings it back, remembered. While it is hidden, a folder is chosen from the folder bar (Windows), the folder button (Linux) or Go to Folder.',
                how: "View > Folder List, the close box on its Folders caption (Windows), or the toolbar's sidebar button (the Mac and Linux).",
                checked: ['The list hides and comes back', 'A folder is still chosen while it is hidden', 'The choice is kept']
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
                shot: 'read-17-find',
                name: 'Reading with the keyboard',
                what: "View > Next Message and Previous Message step through the list; Next Unread Message (N in the list) finds the next unread message and offers the next folder with unread mail when none is left, as Outlook Express does. Edit > Find in This Message finds words in the message shown, with the web view's own find (no script runs in the message).",
                how: 'Ctrl+. and Ctrl+, (Cmd+] and Cmd+[ on the Mac, Ctrl+< for Previous on Linux), N in the list, F3 (Cmd+Option+F).',
                checked: [
                    'Next and Previous Message select the rows below and above',
                    'Next Unread selects the next unread message, then offers the next folder with unread mail',
                    'Find in This Message finds a word of the message, and says when it is not there'
                ]
            },
            {
                shot: 'read-18-go-to',
                name: 'Go to Folder',
                what: 'View > Go to Folder shows the folders of every account in a tree, narrowed as a part of a name is typed, the ones used last at the top; choosing one shows it.',
                how: 'View > Go to Folder, Ctrl+Y (Cmd+Shift+Y on the Mac).',
                checked: ['Go to Folder lists the folders of every account and typing narrows them', 'Choosing Sent Items there shows Sent Items']
            },
            {
                shot: 'threads-1-collapsed',
                name: 'Conversations',
                what: "The list groups the messages that answer each other into conversations (by their Message-IDs, In-Reply-To and References; on Gmail by Gmail's own conversations), one row each on its first message with how many it has, bold while one is unread, placed by its newest message. An action on a collapsed conversation acts on all of its messages.",
                how: 'On by default; Tools > Options > Group messages by conversation turns it off.',
                checked: ['The Inbox lists the conversation once, with its count', 'Mark Read on the collapsed row marks all three read on the server']
            },
            {
                shot: 'threads-2-expanded',
                name: 'Expanding a conversation',
                what: 'The + in front of a conversation (a triangle on the Mac and Linux) or the Right key shows its other messages under it, indented, oldest first; the - (or Left) hides them. View > Expand All Conversations and Collapse All Conversations do it for every conversation of the list.',
                how: 'Click the + or - (the triangle on the Mac and Linux), Right and Left, or the View menu.',
                checked: ['Expanding shows the replies under the first message, collapsing hides them']
            },
            {
                shot: 'threads-3-options-off',
                name: 'One row a message',
                what: 'With Group messages by conversation turned off in Options, every message is a row of its own again.',
                how: 'Tools > Options (Inbox Classic > Settings on the Mac, Preferences on Linux).',
                checked: ['With the option off the three messages are three rows; on again, one']
            },
            {
                shot: 'bounce-1-failed',
                name: 'Why a message bounced',
                what: "A delivery notice opened in the reading pane gets a card above it: not delivered (or not delivered yet), each recipient with the reason in plain words (the address does not exist, the mailbox is full, blocked as spam, a blocklist, and so on) and what you can do, the server's own words under Details. The reasons are told by a neural network built into the app (bounce-classifier), nothing is sent anywhere. Show the message that bounced selects it in Sent Items.",
                how: 'Open a delivery notice.',
                checked: [
                    'The card names the recipient and the reason',
                    "Details show the server's words",
                    'Show the message that bounced selects it in Sent Items'
                ]
            },
            {
                shot: 'bounce-2-delayed',
                name: 'A delayed message',
                what: 'A notice that delivery is only delayed shows an amber card: the server is still trying, nothing to do yet, and when a wait was asked for, how long.',
                how: 'Open a delay notice.',
                checked: ['The delay card says it is still being tried']
            },
            {
                shot: 'otp-1-card',
                name: 'One-time codes',
                what: "A message with a sign-in or verification code has a card above it with the code in large type, the domain it is for, and Copy. The code comes from the sender's OTP-Token header, or from the text, found by a model trained on real mail (pe-otp, a port of otp-detect). It is shown only when the provider of the account says that domain signed the message, and never in Junk E-mail, Sent Items or Drafts; an old code says it has probably expired.",
                how: 'Open a message with a code; click Copy on its card.',
                checked: [
                    'A code in the text of a message the domain signed is shown in a card above it',
                    'Copy puts the code on the clipboard',
                    'An OTP-Token header gives the code and the domain it is for',
                    'An unsigned message has no card'
                ]
            },
            {
                shot: 'bounce-3-list',
                name: 'Bounces in the list',
                what: 'Delivery notices have an undelivered mark in the list, and is:bounce finds them.',
                how: 'Search for is:bounce.',
                checked: ['The notice has the mark in the list', 'is:bounce finds the two notices and nothing else']
            },
            {
                shot: 'threads-4-watch',
                name: 'Watch Conversation',
                what: "Message > Watch Conversation, or the message's right-click menu, watches a conversation: a new message in it is always announced, even from a folder of the user's other than the Inbox, and the notification says the conversation is watched. Both menus check the item while it is watched; choosing it again takes the mark away. When a late message joins two conversations, the joined one is watched if either was, and ignored only if both were.",
                how: 'Message > Watch Conversation, the right-click menu of a message, W in the message list.',
                checked: [
                    'Watch Conversation checks the menu item, in the Message menu and the right-click menu',
                    'A new reply to the watched conversation is announced',
                    'Watch Conversation again takes the check marks away'
                ]
            },
            {
                shot: 'threads-5-ignore',
                name: 'Ignore Conversation',
                what: 'Message > Ignore Conversation turns a conversation grey and marks it read, on the server too; a new message in it arrives read, without a notification. View > Hide Ignored Conversations leaves ignored conversations out of the list.',
                how: 'Message > Ignore Conversation, the right-click menu of a message, K in the message list; View > Hide Ignored Conversations.',
                checked: [
                    'Ignore Conversation greys the row and marks its messages read on the server',
                    'A new reply to the ignored conversation arrives read, without a notification',
                    'Hide Ignored Conversations hides it, and shows it again when turned off'
                ]
            },
            {
                shot: 'read-16-window',
                name: 'A message in a window of its own',
                what: 'Double-click (or Enter) opens a message in a window of its own, as in Outlook Express: its header, pictures, files and text as the reading pane shows them, with Reply, Reply All, Forward, Print, Delete, Archive and Junk, and Previous and Next through the list it came from. Several can be open at once. A draft opens to be finished instead.',
                how: 'Double-click a message in the list, or select it and press Enter.',
                checked: [
                    'Enter opens the message in its own window, titled with its subject, marked read',
                    'Next and Previous step through the list, the title following',
                    'Reply in the window answers that message'
                ]
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
                shot: 'rules-1-list',
                name: 'Message Rules',
                what: 'Tools > Message Rules lists the rules that sort new mail, each with a check box to turn it off, in the order they run; New, Edit, Delete, Move Up and Move Down.',
                how: 'Tools > Message Rules.',
                checked: ['The list opens', 'A rule is added']
            },
            {
                shot: 'rules-2-editor',
                name: 'A rule: a search and what to do',
                what: 'A rule is a query in the search box\'s words (from:, subject:, list:, words of the text) and what to do with the new Inbox mail that matches it: move it to a folder, mark it read, flag, archive, junk, delete, or not notify. It says how many messages in the Inbox match now.',
                how: 'New or Edit in Message Rules.',
                checked: ['Name, query, Move to Archive and Mark as read set']
            },
            {
                shot: 'rules-5-applied',
                name: 'New mail sorted by rules',
                what: 'Mail that arrives in an Inbox is sorted by the rules while Inbox Classic runs; the status bar says how many messages they sorted.',
                how: 'Automatic as new mail arrives.',
                checked: ['The newsletter lands in Archive, not the Inbox', 'The status bar says it was sorted']
            },
            {
                shot: 'rules-3-from-search',
                name: 'A rule from a search',
                what: 'Create Rule on the bar over search results starts a rule with the words searched for.',
                how: 'Search, then Create Rule.',
                checked: ['The editor opens with the words of the search']
            },
            {
                shot: 'rules-4-from-message',
                name: 'Create Rule from Message',
                what: 'Message > Create Rule from Message starts a rule for the sender of the message selected, or its mailing list (list:).',
                how: 'Message > Create Rule from Message, or the message\'s right-click menu.',
                checked: ['The query starts with from:']
            },
            {
                shot: 'rules-6-bad-query',
                name: 'What a rule can not hold',
                what: 'A rule is for the new mail of an Inbox, so a query naming a folder (in:) or a date is refused with the reason.',
                how: 'Save a rule with in: or a date.',
                checked: ['The reason is shown']
            },
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
                how: 'Select a message with an invitation; Open in Calendar on its card.',
                checked: ['A message with an invitation shows the event in a card above the text, with Open in Calendar']
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
                shot: 'select-1-several',
                name: 'Several messages at once',
                what: "Ctrl+click (Command+click on the Mac) and Shift+click select several messages, Select All every message of the list. The reading pane then says how many are selected and how many of them are unread or flagged, the status bar counts them, and Mark Read, Mark Unread, Flag, Junk, Delete, Move and dragging act on all of them, each folder's with one command to the server. Reply, Print and the other commands for one message are off.",
                how: 'Ctrl+click or Shift+click messages in the list; Edit > Select All (Ctrl+A).',
                checked: [
                    'Three messages selected: the reading pane says so, with how many are unread, and so does the status bar',
                    'Reply is off for several, Mark as Read is on',
                    'Mark as Read and Move to Folder act on the three, on the server'
                ]
            },
            {
                shot: 'select-2-undo',
                name: 'Undo',
                what: 'Edit > Undo takes back the last move, delete or junk, however many messages it was: they go back to the folders they came from, found by their Message-IDs where they went, and the keyword junk set is taken away. The menu names what it takes back; the status bar says what was done.',
                how: 'Edit > Undo (Ctrl+Z) after moving, deleting or junking messages.',
                checked: ['The status bar says the messages were moved to Archive', 'Edit > Undo Move brings them back to the Inbox, on the server']
            },
            {
                shot: 'flags-1-colors',
                name: 'Flag colours',
                what: 'Messages are flagged in the seven colours of Apple Mail (red, orange, yellow, green, blue, purple, gray), kept on the server as Apple Mail keeps them: \\Flagged with the keywords $MailFlagBit0 to $MailFlagBit2. A message Apple Mail flagged shows its colour here and the other way round; other mail programs see a flag. The flag column shows the colour.',
                how: 'Message > Flag and a colour, or the message menu; Clear Flag takes it away.',
                checked: [
                    'Orange sets \\Flagged and $MailFlagBit0 on the server, and the flag column shows it orange',
                    'Blue on two selected messages flags both blue',
                    'A message flagged purple by Apple Mail shows a purple flag; Clear Flag takes flag and colour away'
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
                shot: 'organize-8-archive',
                name: 'Archive',
                what: "Archive takes messages out of the Inbox (or a folder of the user's) into the account's Archive folder, made the first time when the account has none. On Gmail it takes every label off instead (the Inbox and the label folders; sent, draft, starred and important stay), so the message is left in All Mail. Undo puts them back, labels included.",
                how: 'Archive on the toolbar, Message > Archive, the message menu, or A in the message list.',
                checked: [
                    'Archive moves the message to Archive on the server, out of the Inbox',
                    'The status bar says it was archived',
                    'Undo puts it back in the Inbox'
                ]
            },
            {
                shot: 'organize-9-empty',
                name: 'Empty Deleted Items and Junk E-mail',
                what: 'Deleted Items and Junk E-mail can be emptied: every message in them deleted for good, after a question that says how many go. It can not be undone, and AI agents can not do it.',
                how: 'File > Folder > Empty Folder, or the right-click menu of Deleted Items or Junk E-mail.',
                checked: ['Empty Folder asks first, saying how many go', 'Junk E-mail is empty on the server and in the list']
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
                what: 'A collapsed account, or a collapsed folder with folders in it, shows the unread messages of the folders it hides, so new mail is not out of sight. Junk E-mail and Deleted Items do not count. Expanded, each folder shows its own again. On the Mac and Linux an account is a heading over its folders, as in Mail: a click opens or closes it, it is never selected, and the folder listed stays listed while its account is closed.',
                how: 'Click an account (on Windows its arrow) or the arrow beside a folder to collapse it.',
                checked: [
                    'Collapsed, the account shows the unread messages of its folders',
                    'The account is a heading that can not be selected (Mac, Linux)',
                    'Expanded, the count is back on the Inbox alone'
                ]
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
                shot: 'files-4-drag-out',
                name: 'Drag messages to the desktop',
                what: 'Messages dragged out of the list onto the desktop, a Finder, Explorer or file manager window, or another program become .eml files there, named after their subjects (Lunch.eml, Lunch (2).eml). A message not downloaded yet is downloaded for it. On Windows the files carry the mark of a download from the internet when they can, on the Mac the quarantine flag.',
                how: 'Drag messages from the list onto the desktop or a folder window.',
                checked: [
                    'Three messages dragged out become three .eml files, named after their subjects',
                    'Each is the message byte for byte, one not downloaded yet included',
                    'Save As with three selected saves the three into a folder, never over a file there'
                ]
            },
            {
                shot: 'files-5-forward',
                name: 'Forward several messages',
                what: "Forward with several messages selected writes one new message with them attached as .eml files, its subject the first one's with Fw:.",
                how: 'Select messages, then Forward (Ctrl+F).',
                checked: ['One new message with the three attached as .eml files', "Its subject is the first one's, with Fw:"]
            },
            {
                shot: 'files-6-drop-in',
                name: 'Drop .eml files onto a folder',
                what: 'Files dropped from the desktop or a file window onto a folder in the tree (or onto the message list, for the folder shown) are put in that folder as Import Messages does, on the server too. Files that are not messages are turned away.',
                how: 'Drag .eml files onto a folder in the tree.',
                checked: ['.eml files dropped onto Archive are in it, on the server', 'A file that is not a message is turned away']
            },
            {
                shot: 'files-4-open-eml',
                name: 'Opening .eml files',
                what: 'A message file opened from Finder, File Explorer or the file manager opens in a message window, the same as a message of the list, with Reply, Reply All, Forward, Print and Save As. Options can make Inbox Classic the app for .eml files (on Windows through its Default Apps).',
                how: 'Double-click an .eml file, or Open With Inbox Classic.',
                checked: ['The file opens in a message window with its subject', 'Reply from it opens a reply']
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
                shot: 'write-20-autosave',
                name: 'Saved as you write',
                what: 'A message being written is saved in Drafts by itself a few seconds after typing stops, and every half a minute while it goes on; the status bar says when. Closing it still asks, and No (Don\'t Save on the Mac) removes a copy only the automatic saving made.',
                how: 'Automatic while writing.',
                checked: ['Saved in Drafts without pressing Save', 'The draft is on the server', 'No removes the copy saved automatically']
            },
            {
                shot: 'write-21-restored',
                name: 'Nothing lost in a crash',
                what: 'The messages that were being written when Inbox Classic or the computer stopped unexpectedly open again at the next start, as they were last saved, and the status bar says they were restored. Closing one without saving leaves its draft in Drafts.',
                how: 'Automatic at start.',
                checked: ['The message opens again with its recipient', 'It says it was restored', 'Closed, it is not opened again']
            },
            {
                shot: 'write-22-undo-send',
                name: 'Undo Send',
                what: 'A message sent waits a few seconds before it goes: the status bar counts down beside an Undo button, and Edit > Undo Send does the same. Quitting sends what waits at once.',
                how: 'Send, then Undo in the status bar or Edit > Undo Send.',
                checked: ['The status bar counts down', 'Edit names Undo Send', 'Left alone, it goes once its time came']
            },
            {
                shot: 'write-23-undone',
                name: 'Taken back, open again',
                what: 'Undo opens the message again as it was, and the status bar says it was not sent. Nothing reaches the recipient.',
                how: 'Undo while the message waits.',
                checked: ['The message opens again with its recipient', 'The status bar says it was not sent', 'It never goes']
            },
            {
                shot: 'write-24-send-delay',
                name: 'Wait before sending',
                what: 'How long a message waits to be taken back: Off, 5, 10 (out of the box), 20 or 30 seconds.',
                how: 'Tools > Options (Settings on the Mac, Preferences on Linux).',
                checked: ['The five waits are offered', '10 seconds chosen']
            },
            {
                shot: 'write-25-attachment-reminder',
                name: 'Did you forget the attachment?',
                what: 'A message whose subject or text says a file is attached (in English, German, Estonian, Spanish or French), with none attached, asks before it goes. The signature and the quoted message do not count.',
                how: 'Happens on Send.',
                checked: ['It asks, naming the word', 'Going back keeps the message open', 'Sending anyway sends it']
            },
            {
                shot: 'account-12-other-addresses',
                name: 'Other addresses you send from',
                what: 'Account Properties takes the other addresses an account sends from (aliases), comma separated: Name <address> or the address alone.',
                how: 'File > Accounts > Properties (or the account\'s right-click menu).',
                checked: ['Properties keeps the other addresses']
            },
            {
                shot: 'write-26-from-alias',
                name: 'Send from another address',
                what: 'From lists each account with its other addresses after it; a message goes from the one chosen, with its name. An address that is not the account\'s is refused.',
                how: 'The From list of a message.',
                checked: ['From offers the other address', 'It goes from that address, with its name']
            },
            {
                shot: 'write-27-reply-from-alias',
                name: 'A reply from the address it was sent to',
                what: 'A reply (or a forward) to a message sent to one of the account\'s other addresses goes from that address; Reply All leaves out every address of the account.',
                how: 'Reply to such a message.',
                checked: ['The reply goes from the other address']
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
        title: 'The Address Book',
        intro: 'People and groups the user keeps, as in Outlook Express: Tools > Address Book, Select Recipients behind the To, Cc and Bcc buttons of a message, completion that offers the book first, Add Sender to Address Book, and vCard and CSV files in and out.',
        features: [
            {
                shot: 'contacts-1-book',
                name: 'The Address Book',
                what: 'Groups on the left, people on the right with their name, default e-mail address and phone, a find box that finds them by the start of a name, nickname, company or address, and New Contact, New Group, Properties, Delete and Write To. The book is kept in the local store, never on the server.',
                how: 'Tools > Address Book, or Ctrl+Shift+B.',
                checked: ['It opens empty with its toolbar', 'It lists the contact saved, found by part of the name and not by other words']
            },
            {
                shot: 'contacts-2-person',
                name: 'Contact Properties',
                what: 'First and last name, the name shown, nickname, company, several e-mail addresses with the default first (Set as Default), phone numbers by kind and notes. An address that is not one mailbox alone is refused; what a vCard brought that the form does not show is kept.',
                how: 'New Contact, or Properties or a double-click on a contact.',
                checked: ['A contact with a name and two addresses is saved, the first the default']
            },
            {
                shot: 'contacts-3-group',
                name: 'Group Properties',
                what: 'A name and members: people from the Address Book (Select Members), who follow their card when it changes, and addresses typed that are in no card.',
                how: 'New Group, or Properties on a group.',
                checked: ['A group of the contact and a typed address is saved and listed with its two members']
            },
            {
                shot: 'contacts-4-pick',
                name: 'Select Recipients',
                what: "Outlook Express's picker: the To, Cc and Bcc labels of a message are buttons that open the Address Book's people and groups, with To ->, Cc -> and Bcc -> to choose where each goes. A group puts its members in the field, and an address already there is not added again. Typing a group's name in a field completes to its members, the book's people and groups offered before those only written to or heard from.",
                how: 'Click To, Cc or Bcc in a message.',
                checked: [
                    'To opens Select Recipients with the group and the contact',
                    'The group and the contact go to To, each address once',
                    "Typing the group's name completes to its members"
                ]
            },
            {
                shot: 'contacts-6-picture',
                name: "A contact's picture",
                what: "Contact Properties takes a picture (PNG or JPEG, chosen or dropped on it), kept as the app's own small copy. It shows in the column layout's rows and the reading pane for that contact's mail, but only when the mail provider confirms the message comes from that domain, so a forged sender never gets a real person's face. A brand's logo comes first; vCard files carry the picture in and out.",
                how: 'Tools > Address Book, a contact, Properties: Choose or Remove beside the picture.',
                checked: ['The picture is kept', 'Shown for confirmed mail', 'A forged sender gets the initials', 'Removed again']
            },
            {
                shot: 'contacts-5-import',
                name: 'Import and export, Add Sender',
                what: "File > Import Address Book reads vCard (.vcf) and CSV files as Outlook, Thunderbird, Google Contacts and Apple's Contacts write them, and skips a contact whose addresses are all in the book; File > Export Address Book writes a vCard file. Add Sender to Address Book (Tools and the message's right-click menu) adds the sender of a message once.",
                how: 'File > Import Address Book, File > Export Address Book, Tools > Add Sender to Address Book.',
                checked: [
                    'Add Sender adds the sender once',
                    'A file of two contacts, one in the book already, adds 1 and skips 1',
                    'The export holds every contact'
                ]
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
                what: "The help in short topics, in the platform's own way: on Windows a help window with Contents and Search beside the topic, Back, Forward and Print; on the Mac a Help Book in Help Viewer, whose topics the Help menu's search finds; on Linux Yelp where it is installed, otherwise a help window with a search over the contents. Every key and control name comes from the app itself, so the help names them as the app does, in the language in use. F1 (Command-? on the Mac) in a window or dialog opens its own topic. The same help is on inboxclassic.com/help.",
                how: 'F1 or Help > Contents; Command-? on the Mac.',
                checked: [
                    'The help opens at the topic of the window it was asked in',
                    'The contents list the sections and topics',
                    'A search lists the topics with every word, a link opens a topic, Back returns'
                ]
            },
            {
                shot: 'options-1-language',
                name: 'Options and the language',
                what: "Tools > Options (Settings on the Mac, Preferences on Linux) chooses the language of the windows: System default, or English, Deutsch, Eesti, Español or Français, each named in itself. The app starts again in it. Notify of New Mail is there too. On Windows the installer asks for the language on a first install; on the Mac the system's own per-app language setting chooses it too.",
                how: 'Tools > Options, Language.',
                checked: [
                    'Language lists System default and the five languages by their own names',
                    'A language chosen says the app starts again to change it, with Restart Now and Later'
                ]
            },
            {
                shot: 'lang-1-german',
                name: 'In German',
                what: 'Every word of the windows comes from the catalogs of the core (Fluent), the same on every platform: menus, toolbar, dialogs, status bar, the reading pane, the help. Dates and sizes follow the language too.',
                how: 'Choose Deutsch in Options.',
                checked: ['Started in German, the menus, the toolbar and the status bar are in German']
            },
            {
                shot: 'lang-2-pseudo-main',
                name: 'Pseudo-language: the main window',
                what: 'A test language made from English, 40% longer and bracketed, that shows any word not yet in the catalogs and any layout too narrow for longer languages.',
                how: 'Started with --language qps (tests only).',
                checked: ['Nothing in the main window is left in English, and nothing is cut off']
            },
            {
                shot: 'lang-3-pseudo-form',
                name: 'Pseudo-language: a form',
                what: 'The Add Mail Account form in the pseudo-language: its labels and buttons fit their longer words.',
                how: 'Started with --language qps (tests only).',
                checked: ['Nothing in the account form is left in English, and nothing is cut off']
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
        'tray-3-badge',
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
        'tray-3-badge',
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
