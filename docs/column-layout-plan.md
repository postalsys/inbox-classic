# A column layout for wide windows, rows of several lines and sender pictures: plan

On a large monitor the classic layout (folders on the left, the message list above the reading pane) wastes the width:
the list is one very long line a row, and the reading pane is a short, very wide strip. This plan adds a second layout
with three panes side by side (folders, messages, the message), picks between the two by the window's width unless the
user chose one, lets the folder list be hidden, and gives the narrow message list rows of several lines with the
sender's picture. Overview: `docs/column-layout-overview.html`.

Nothing here is started. It was written while another session works on `perf/user-first`; phases 2 and 4 touch
`pe-core/src/worker/background.rs` and start after that branch is merged.

## What is there now

- **One layout, hard-coded, on all three.** Windows: `Layout()` in `app/src/main.cpp:832` (tree, list, reader rects;
  the splitters are the gaps, `SplitterAt` and `DragSplitter`). Mac: two plain `NSSplitView`s in `Mailbox.swift:145`.
  Linux: two `gtk::Paned` in `mailbox.rs:160`, with `narrow_layout` breakpoints (1000, 760, 560) that move the folders
  into a popover in a narrow window.
- **No layout command.** View has nothing to hide the folder list or move the reading pane (`core/commands.toml`).
- **The list is one line a row.** Windows: a report mode ListView, `LVS_OWNERDATA`, custom draw (`mailbox.cpp:232`),
  whose rows cannot be made taller as it is. Mac: a view-based `NSTableView`, `rowHeight = 20`. Linux: a
  `gtk::ColumnView` over a paged model.
- **A row has no text of the message.** `PeMessage` has the sender, subject, date and flags. The search text goes to a
  contentless FTS5 index and cannot be read back.
- **Brand logos (BIMI) show in the reading pane only**, 48 pixels, from the opened message's source
  (`pe-core/src/bimi.rs`, `pe_logo_start`). The verdict (`bimi=pass` and `dmarc=pass` in the provider's own
  Authentication-Results) is worked out when a message is opened and stored nowhere; the downloaded SVG is kept for the
  run only.
- **The Address Book has no pictures.** A vCard's PHOTO is kept as text in `cards.extra`. The core has resvg, but no
  JPEG or PNG decoder of its own.
- Found on the way, Windows: the splitter positions and the window's place are not remembered, the main window has no
  minimum size, and the list's header shows no sort arrow.

## The design

### Two layouts

|                   | Classic (today)                    | Columns (new)                                  |
| ----------------- | ---------------------------------- | ---------------------------------------------- |
| Panes             | folders, then list above message   | folders, list, message side by side            |
| List rows         | one line, columns with headers     | three lines with a picture, no column headers  |
| Sorting           | click a column header              | a "Sorted by" button above the list            |
| Good for          | windows up to about 1300 wide      | wide and maximized windows                     |
| What takes growth | the list and the reading pane both | the reading pane only (the side panes keep it) |

- **View > Layout**: Automatic, Classic, Columns (one checked). The same choice in Options ("Layout").
- **Automatic** (the default) is decided by one function in the core, `layout_for(mode, width, current)`, in
  platform-independent pixels (96 DPI units, points, sp), so the three apps switch at the same widths: to Columns at
  1320 or wider, back to Classic under 1200. The gap between the two numbers keeps the layout from flipping back and
  forth while the window's edge is dragged near the line.
- **An explicit Columns holds** down to 900; narrower than that the window shows Classic without changing the setting
  (on Linux the existing breakpoints then take over as today).
- **Switching keeps** the selection, the keyboard focus, the open conversations and the selected row in view.
- **Each layout remembers its own sizes**: the folder list's width (shared), the list's height in Classic, the list's
  width in Columns (360 at first, at least 280, at most half of what the folders leave).
- **The reading pane on a very wide screen**: plain text messages get a line length limit in the preview document
  (about 46em, at the left), so a 2000 pixel pane does not make 300 character lines. HTML mail keeps its own widths.
- The name is **Columns**, not "Wide" or "Vertical": Thunderbird uses both of those for other things, and Apple Mail
  says "column layout".

### Hiding the folder list

A command `folder_list` (View > Folder List, a check mark), in both layouts, remembered.

| Platform | The button                                                      | Key        | With the list hidden                                                             |
| -------- | --------------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------- |
| Windows  | a close box on a "Folders" caption above the tree, as OE had    | F9         | the folder bar's title becomes a drop-down that shows the tree, as OE did        |
| Mac      | the sidebar button at the toolbar's leading edge                | Ctrl+Cmd+S | Go to Folder; dragging the divider to the edge collapses and brings it back      |
| Linux    | a `sidebar-show-symbolic` toggle at the start of the header bar | F9         | the folder button's popover that the narrow layout already has (`narrow_layout`) |

The list is never hidden by itself (but for Linux's narrow window, which does so today). Unread counts stay in reach:
the folder bar and the popover show them.

### A row of three lines (Columns only)

```
 ●  [pic]  Ann Lee                                  10:42
           Quarterly numbers, final version      📎  ⚑
           Here are the figures we talked about on Mo…  3 ›
```

- **Line 1**: who (bold while unread), the date at the right. Sent, Drafts and Outbox show "To: " and the recipients,
  as the classic list shows its Recipients column there.
- **Line 2**: the subject; at the right the attachment and flag marks (the flag in its color).
- **Line 3**: the first words of the message in the secondary text color; at the right the conversation's count and
  its opener. In a search or All Inboxes the folder's name stands at the right of line 2.
- **Left**: a gutter for the unread dot, then the picture, 32 pixels (round on the Mac and Linux, square on Windows to
  go with the classic look).
- **Dates are short**: the time today, the weekday in the last six days, day and month this year, the full date
  before. The apps keep formatting dates in the system's own format as they do; the rule is the same on all three.
- **Conversations**: the head row has the count, the newest message's date and its own first words; opened, its messages
  follow as rows of the same height, indented. (Built so: one row height keeps every list virtual on all three.)
- **The height is fixed** (three lines even while the text line is still empty), so the lists stay virtual and fast and
  nothing jumps when the text arrives.
- **"Sorted by Date ▾"** above the list, beside the search box's row: Date, From, Subject, Size, Flag, Attachment, then
  Newest on Top / Oldest on Top. The same items as **View > Sort By** in both layouts, which gives Classic keyboard
  sorting too (and Windows' header gets its missing sort arrow).
- **Classic rows do not change**: one line, the columns, no picture.
- Screen readers get a row as "Unread, Ann Lee, Quarterly numbers, 10:42, Here are the figures…"; the words come from
  the core's catalog.

### The text line

- `pe-store` migration 23: `messages.snippet TEXT` (NULL: not known yet, empty: the message has no text).
- Written by the core where it has the text already: when the background worker fetches a message's text for the
  search (`fetch_texts`, decoded in `pe-core/src/search.rs`) and when a downloaded source is parsed. No new download
  for new mail.
- **What it holds**: only what the sender wrote, by `pe-content`'s `analyze()` (no quoted reply, no forwarded header),
  white space folded, the invisible padding of marketing mail (zero width characters, runs of `&nbsp;`) removed, cut at
  a word to at most 200 characters.
- **Mail stored before**: its text is in the search index, which cannot be read back. Messages with a downloaded
  source are done from it, locally (a migration marks the sources to be read again at the next start); the rest are
  fetched again by the background worker (text parts only, as before), each account's newest first, after everything
  `open-speed-plan.md` gives it to do. Until then a row's third line is empty. (Built: newest first across the account,
  not the folder on screen first, which would need the worker to know what the windows show.)
- `PeMessage` gains `snippet`. A conversation's head row carries its own (the first message's, which selecting it
  opens, beside its sender and subject), while its date is the newest message's as before.

### Sender pictures

One picture a row, chosen by the core in this order:

1. **The brand's logo (BIMI)**, when the provider's own Authentication-Results say `bimi=pass` and `dmarc=pass`: the
   rule the reading pane uses today (`bimi::of`).
2. **The contact's picture**, when the sender's address is in the Address Book with a picture **and** the message is
   confirmed to come from that domain (`pictures::from_verified`, the rule of trusted senders). Never in Junk E-mail.
   A forged "boss@company.com" does not get the boss's face. (Built without the first draft's fallback for a provider
   that gives no verdict: Microsoft's Authentication-Results carry no authserv-id, so every message there, forged ones
   too, would have had no verdict and shown the face.)
3. **The placeholder**: one or two initials (from the name, else the address; worked out in the core, Unicode aware) in
   the secondary text color on a faint neutral fill. One quiet tone for everyone, no color per sender, so real logos
   and pictures are what the eye finds.

BIMI first is as asked, and it is also the safer order: the logo is checked against the message, the contact's picture
is matched by an address.

What the core needs for it:

- **The verdict per message.** `pe-sync` fetches three header fields with the summaries
  (`BODY.PEEK[HEADER.FIELDS (AUTHENTICATION-RESULTS BIMI-LOCATION BIMI-SELECTOR)]`; not `BIMI-Indicator`, which carries
  a whole SVG). The core stores `messages.sender_auth` (bits: from verified, logo allowed) and `messages.logo_id`.
  Mail stored before gets them in the same background pass as the text line, in the same FETCH.
- **Logos kept.** A table `logos(id, domain, url, svg, fetched, failed)`: one download a sender's domain and URL, kept
  for 30 days, a failure remembered for a day. The list never downloads a logo a message at a time, so a logo's URL
  cannot be used to see who opened what. Checked and drawn by the existing `bimi::render` (32 KB at most, no scripts,
  no outside resources).
- **Contact pictures.** `card_pictures(card_id, png)`. `pe_card_set_picture(card, path)` reads the file in Rust (PNG
  or JPEG, by a decoder crate with only those two formats on; size limits on the file and its dimensions), cuts the
  middle square, scales it to 256 and stores our own PNG; `pe_card_remove_picture`. A vCard's embedded PHOTO is
  imported the same way and exported again; a PHOTO that is a URL is never fetched.
- **To the apps**: `PeMessage` gains `picture` (a key, 0 for none), `picture_kind` and `initials`.
  `pe_picture_start(core, key, size)` and `pe_picture_result` give BGRA pixels through the event callback, as
  `pe_logo_start` does; the apps keep a small cache by key and size, so fifty rows from one sender cost one picture.
  The apps decode nothing.
- **The reading pane** shows the contact's picture too where it shows the logo today (same order; no placeholder
  there).
- **Address Book > Contact Properties**: a picture well with Choose… and Remove; a picture file can be dropped on it.
- **Options**: "Show senders' pictures in the message list", on.

## In each app

### Core

- `pe-core/src/layout.rs`: `layout_for` and its numbers, tested. C API `pe_layout_for`.
- `core/commands.toml`: `layout_automatic`, `layout_classic`, `layout_columns`, `folder_list` (toggle), `sort_date`,
  `sort_from`, `sort_subject`, `sort_size`, `sort_flag`, `sort_attachment`, `sort_newest_first`, `sort_oldest_first`
  (Windows ids from 155). If the generator has no way to say "a submenu", it gets one (`submenu = "layout"`); the
  three apps build menus from the table.
- Strings in every language: the commands, "Sorted by { $field }", "To: ", the row's accessible words, the Options
  lines.
- The preference (`Layout`: automatic, classic, columns; `FolderList`; the sizes) stays a plain preference of each app.

### Windows (`app/`)

- `Layout()` gets the mode: in Columns the second splitter is the vertical gap between list and reader; `g_listWidth`
  beside `g_listHeight`. The window's place, both splitters and the list's width are saved in the registry;
  `WM_GETMINMAXINFO` for a minimum size.
- The list: `LVS_OWNERDRAWFIXED` has to be set when a ListView is made, so switching layouts makes the list again
  (owner draw, `LVS_NOCOLUMNHEADER`, one column, the row height from `WM_MEASUREITEM`) and gives it the view, the
  selection and the scroll place back. Rows drawn in `WM_DRAWITEM` with the fonts and system colors the custom draw
  uses now; pictures as DIB sections with `AlphaBlend`, as `reader.cpp` does. **A spike first** (half a day) to
  confirm owner draw with `LVS_OWNERDATA`, keyboard, multi-selection and MSAA names behave; if not, the fallback is a
  tall small image list with custom draw.
- The "Sorted by" strip: a flat button with a popup menu, in the row of the search bar.
- The folder list: the caption with its close box, the folder bar's drop-down (a popup window holding the tree), a
  toolbar button.
- Options: a Layout combo, the pictures check box. Contact Properties: the picture well.

### Mac (`mac/`)

- `rightSplit.isVertical` follows the layout; an autosave name a layout ("ListAndReader", "ListBesideReader"); the
  list's side keeps its width when the window grows (holding priorities).
- The list: in Columns one column, no header view, `rowHeight` 58, a new `MessageRowCell` (unread dot, picture, three
  text fields), as Mail's column layout looks. The same table, data source and selection.
- The sidebar: a split view delegate (`canCollapseSubview`), a toolbar item with `sidebar.leading`, the command.
- The decision runs in `windowDidResize`; Settings gets a Layout popup row and the pictures check box; the Address
  Book's sheet gets the picture well (`NSImageView`, editable for drops, the file's path handed to the core).

### Linux (`linux/`)

- `right.set_orientation()` follows the layout; `ListWidth` beside `ListHeight` in `settings.ini`.
- The list: a `gtk::ListView` with a row factory beside the `ColumnView` in a `gtk::Stack`, on the same `MessageModel`
  and selection model. The placeholder is drawn by the app (not `AdwAvatar`, whose colors stand out).
- Breakpoints: Columns sits above the existing ones; `narrow_layout` stays as it is under 1000.
- The header bar's sidebar toggle uses the popover path that is there. Preferences: a `ComboRow` and a switch row.

## Tests

- **Core**: `layout_for` (both numbers, the gap, explicit modes, the 900 floor); snippets (quoted replies left out,
  padding removed, cut at a word, HTML only mail, empty mail, a conversation's head); the picture order (logo, then
  contact, then initials; a forged sender; Junk; a provider without Authentication-Results); initials (two names, one
  name, an address, non-Latin names, emoji); contact pictures (PNG, JPEG, a huge one, a broken one, a vCard round
  trip); the migrations and the query plans; `e2e_core` and `e2e_ffi` for the new calls, with ImapKit messages that
  carry Authentication-Results.
- **UI end-to-end, all three**: the existing steps **pin Classic at their start**, since Linux's test window is 1600
  wide and Automatic would otherwise turn every existing screenshot into Columns. New steps in `SCENARIO.md` with
  screenshots: `layout-1-columns`, `layout-2-automatic` (the window made wide, then narrow), `layout-3-folders-hidden`,
  `layout-4-sort`, `layout-5-conversation`, `pictures-4-list`, `contacts-6-picture`; entries in `feature-map.mjs`.
- **Help**, five languages (translations marked for review): a new topic "Layouts and the folder list", and the
  changes in read-messages, find-messages (sorting), address-book and options. F1 context unchanged.
- **The homepage**: a Columns screenshot a platform through `homepage-screenshots.sh`.
- The UX review rounds of `next-features-plan.md` on the Mac and Linux screenshots (light, dark, the pseudo-language,
  a long name, a long subject, no text, right-to-left names); what Windows still owes goes to
  `build/windows-ux-pending.md`.

## Order of work

Each step is one pull request that lands on all three apps and can ship by itself.

1. **The folder list can be hidden**, and Windows remembers its window and splitters. Small, useful in Classic already.
2. **The text line in the core**: the migration, writing it, the pass over old mail. No C API change, no app change.
   After `perf/user-first` is merged.
3. **The Columns layout**: `layout_for`, the commands, the three-line rows (with the text line, without pictures),
   "Sorted by" and View > Sort By, Options, Automatic, the plain text line length. The largest step; the Windows spike
   comes first.
4. **Pictures in the list**: the headers fetched with the summaries, the verdict and the logos stored, the
   placeholder, `pe_picture_start`, the option.
5. **Contact pictures**: the Address Book's picture, vCard PHOTO, the order with the logo, the reading pane.

## Decided

Decided with Andris on 2026-11-13:

1. **Automatic is the default for everyone**, those who update too. Only windows 1320 or wider change; the status bar
   says once "The window is wide enough for the column layout. View > Layout changes it.", and View > Layout > Classic
   brings the old look back for good.
2. **The name is Columns**: View > Layout > Automatic, Classic, Columns.
3. **A contact's picture shows for confirmed senders only**, never in Junk E-mail.
4. **The logo comes before the contact's picture**; the contact's picture is used where there is no logo.
5. **The placeholder is quiet initials**: one muted tone for everyone, no color per sender.
6. **Rows in Columns always have three lines.** No setting for the text line.
7. **Classic rows get no pictures.** Classic stays as it is.
8. **Mail stored before is filled in by a background pass over all of it**: newest first, after the worker's other
   work.

Still open, to settle by trying it: the numbers (1320 up, 1200 down, 900 as the floor of an explicit Columns).

## Risks

- **Windows' owner drawn list** is the one unknown; hence the spike, and the fallback.
- **Providers that say nothing about BIMI** (Gmail does not expose its verdict in Authentication-Results): fewer logos
  than Gmail's own page shows. A later step could look the record up itself over DNS-over-HTTPS
  (`default._bimi.<domain>`), which `pe-autoconfig/src/dns.rs` can nearly do (it has no TXT query yet), but without
  checking the certificate (VMC) that would trust any domain's own claim, so it is left out here.
- **Three more header fields a message** make the summaries' FETCH a little larger; Authentication-Results can be a
  few hundred bytes. Measure it against a large folder's first sync before step 4 lands.
- **The pass over old mail** fetches text again for mailboxes indexed before. It runs last in the background and can
  be stopped with the existing download settings.
- **A second image decoder in the core** (PNG, JPEG) reads files the user picked and vCards they imported: Rust only,
  size limits, fuzzed with the corpus of the crate, and the stored picture is always our own PNG.
