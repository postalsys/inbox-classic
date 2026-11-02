#!/usr/bin/env node
// Builds a single HTML page that maps every feature of the app to a screenshot from the UI end-to-end test
// (scripts/ui-e2e.ps1, copied here by scripts/win-ui-e2e.sh), with the screenshots embedded:
//   node scripts/feature-map.mjs [screenshot dir, default build/ui-e2e] [output, default build/feature-map.html]

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const dir = process.argv[2] || 'build/ui-e2e';
const out = process.argv[3] || 'build/feature-map.html';
const version = /version = "([^"]+)"/.exec(readFileSync('core/Cargo.toml', 'utf8'))[1];

// each feature: the screenshot, what it does, how to reach it, and what the UI test checks
const sections = [
    {
        title: 'Adding an account',
        intro: 'The first start opens the account form; File > New Account adds more. Two steps: who you are, then the servers.',
        features: [
            {
                shot: 'account-1-form',
                name: 'Step 1: name, address, password',
                what: 'Three fields, nothing technical. The servers are looked up from the address after OK.',
                how: 'First start, or File > New Account.',
                checked: ['The form opens on the first start']
            },
            {
                shot: 'account-3-servers',
                name: 'Step 2: the servers, looked up',
                what: "Inbox Classic looks up the provider's settings the way Thunderbird does: the provider's own autoconfig file, then Mozilla's ISPDB, then the usual imap. and smtp. names. Only over HTTPS, and it never picks a server without encryption. Gmail and Outlook.com accounts are offered sign-in through the browser (OAuth) when the build has client IDs.",
                how: 'Follows step 1 automatically. Cancel on the lookup skips it.',
                checked: ['The lookup runs and fills in the guessed names (imap.postalexpress.test for the test address)']
            },
            {
                shot: 'account-6-gmail',
                name: 'Providers recognized by their mail servers',
                what: "The lookup works like EmailEngine's: the servers that receive the domain's mail (MX) are checked against a table of hosted providers (Google Workspace, Microsoft 365, Zoho, AWS WorkMail, Yandex and more), then the domain's SRV records, the provider's settings file, Thunderbird's database and Microsoft Autodiscover race, and the first answer wins. DNS questions go over DNS-over-HTTPS, so nobody on the network can hand out other servers. The form says where the settings came from.",
                how: 'Automatic in step 2. For Exchange, the password is offered only to the Autodiscover server of your own domain that asks for it, over an encrypted connection.',
                checked: ['A Gmail address gets imap.gmail.com and smtp.gmail.com, found by its MX']
            },
            {
                shot: 'account-5b-browser-sign-in',
                name: 'Gmail sign-in through the browser',
                what: "For a Gmail or Google Workspace address Inbox Classic offers to sign in on Google's own page in the web browser (OAuth 2.0 with PKCE, Google's Desktop App flow): the password and any second step are typed there, never into Inbox Classic, and the account then signs in with tokens kept in the Windows Credential Manager. Outlook.com and Microsoft 365 addresses sign in the same way on Microsoft's page.",
                how: 'Answer Yes when it is offered after the lookup; the browser opens, and the account is added once Google sends you back.',
                checked: ['The offer appears for a Gmail address', 'No goes on to the password way']
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
                name: 'Find',
                what: 'The Find box narrows the list to the messages with what you type in their subject, sender name, sender address or recipients, as you type. The status bar counts what it found. Esc, an empty box or another folder shows the whole folder again.',
                how: 'The Find box at the right of the toolbar, Edit > Find Message, or Ctrl+Shift+F.',
                checked: [
                    'A subject word finds that message only',
                    'A sender address is found',
                    'Nothing is listed for what nothing has',
                    'Clearing it shows the whole folder'
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
                what: 'From shows the account the message goes from (name and address), and with several accounts chooses another. To, Cc, Bcc, Subject, the text and attached files (Attach, or dragged from Explorer), listed with their size; Delete or a right-click takes one off. Several addresses are separated with commas; names with commas go in quotes.',
                how: 'Create Mail on the toolbar, Message > New Message, or Ctrl+N.',
                checked: ['From names the account', 'Attach adds the files', 'Delete takes one off', 'The message is sent and arrives with only the file left']
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
                name: 'Outbox and Send Later',
                what: 'Every message goes through the Outbox: one that can not go (offline, refused) waits there with the reason and goes with the next Send/Recv, so nothing is lost. Send Later only queues it. The status bar counts what waits; Tools > Outbox lists each message with when it was queued and whether it waits or why it did not go.',
                how: 'Send Later in the compose window; Tools > Outbox to send now or delete.',
                checked: ['Send Later does not send yet', 'The Outbox lists the message', 'Send All Now sends it']
            },
            {
                shot: 'write-8-save-draft',
                name: 'Drafts',
                what: 'Save keeps the message in the Drafts folder on the server, in place of the copy saved before. Closing a message with changes asks: Yes saves it in Drafts, No throws it away, Cancel goes back to it.',
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

const missing = ['Gmail and Outlook.com browser sign-in in released builds: works, but needs the OAuth client IDs at build time'];

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
<nav>${sections.map((s, i) => `<a href="#s${i}">${esc(s.title)}</a>`).join('')}<a href="#behind">Behind the scenes</a><a href="#missing">Not there yet</a></nav>
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
<section id="missing"><h2>Not there yet</h2><p class="intro">What an Outlook Express user would look for and does not find yet.</p><ul class="missing">${missing.map(m => `<li>${esc(m)}</li>`).join('')}</ul></section>
</main>
<footer>${count} features. Generated ${new Date().toISOString().slice(0, 10)} by scripts/feature-map.mjs from the screenshots of scripts/ui-e2e.ps1.</footer>
</body>
</html>
`;
writeFileSync(out, html);
console.log(`${out}: ${count} features`);
