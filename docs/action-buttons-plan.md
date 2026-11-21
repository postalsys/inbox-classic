# Actions as buttons: the mailing-list bar and the other links

Every action in the app should look like one. A review of the UI tests' screenshots on 2026-11-21 found eight places on Windows and the Mac where an action is drawn as a hyperlink or as a click-anywhere bar, and Unsubscribe, the most visible of them, is also in a different place on each platform and forgets it was used. Part 1 replaces Unsubscribe with a mailing-list bar; part 2 turns the other link actions into buttons. A link is kept only where it opens an explanation and changes nothing ("Why?").

Reviewed against the code twice on 2026-11-21; what the second review changed is at the end.

# Part 1: Unsubscribe, a mailing-list bar

## What the screenshots show (2026-11-21)

From `read-8-unsubscribe` and `read-9-unsubscribe-ask` of the three UI tests:

1. **It looks like a link, among buttons.** The attachments ("1 file"), the bounce card ("Show the message that bounced") and Create Rule are buttons; Unsubscribe is blue underlined text (orange on Linux). A link promises a web page, but the usual case, a one-click request, opens none. The help already calls it "the Unsubscribe button".
2. **It is in a different place on each platform.** The Mac puts it top right, beside From, where the attachments button also goes; Windows bottom right, beside Subject; Linux after the subject. The three apps are meant to share one layout.
3. **Linux draws it in the accent orange-red**, which reads as a warning on a harmless action.
4. **It does not say what you leave.** Nothing names the list; the only clue is the sender.
5. **Only the mouse reaches it.** There is no menu command, no right-click entry and no shortcut, so keyboard and screen reader users must tab into the header to find it.
6. **It forgets.** After a request the link stays as it was and only the status bar says what happened, so people click again, and a list that keeps sending gives no hint that the request did not work.
7. **The question's buttons** are Yes and No on the Mac for a one-click request (OK and Cancel for the other two), where Apple and GNOME ask for a verb.

## Decided

| Question        | Answer (2026-11-21)                                                                                                                                                                                                                 |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The control     | An info bar above the message body with an Unsubscribe button, the same on all three apps                                                                                                                                           |
| What it names   | The list's domain only, never the name the sender chose: "This message is from a mailing list (list.example.com)." A phishing message must not make the app's own bar say "Your Bank Security". The same rule as the OpenPGP labels |
| With other bars | Stacked, in a fixed order: download failed, pictures blocked, mailing list. One message and one button a bar                                                                                                                        |
| Menus           | "Unsubscribe..." in the Message menu and the message's right-click menu; no default shortcut                                                                                                                                        |
| After a request | The core remembers each list asked to leave, with the date, and the bar says so on every message of that list                                                                                                                       |
| The question    | Verb buttons on the Mac and Linux (Unsubscribe, Cancel); Windows keeps its classic Yes and No message box                                                                                                                           |

## Defaults chosen (say if you want otherwise)

- **Where the bar is shown**: on a message whose List-Unsubscribe the core can act on, in the reading pane and in message windows. Not in Junk E-mail, Sent Items or Drafts, and the menu command is disabled there. This is a change: today the link shows in Junk E-mail too, where unsubscribing confirms the address to a spammer (which is why agents may not do it there).
- **The domain**, from the core: for a one-click list the domain whose signature the provider confirmed (the one the request is trusted for today); else the host of the List-Id, else of the sender's address. Only a valid host name is shown (letters, digits, hyphens and dots, an internationalized one in its `xn--` form, 80 characters at most); otherwise the bar says "This message is from a mailing list." without one. The button says "Unsubscribe..." (the dots: it asks first).
- **Remembered per list and account**: by the List-Id the store already keeps for each message (`messages.list_id`), else by the From address. Agent requests count too.
- **After a request**: the bar reads "You asked to leave this list on 21 November 2026." with no button. A one-click request is remembered when the list accepts it, an e-mail one when its draft is sent, a web page one when the page is opened (the app can not see the page, so the bar says "You opened the list's page to leave it on ..." and keeps its button).
- **When the list keeps sending**: decided for each message by itself, from when it arrived. A message that arrived up to two days after the request (the time RFC 8058 senders are given), or before it, says only when you asked. One that arrived later brings the button back: "You asked to leave this list on 21 November, but this message came after. [Unsubscribe again...]". No search through the folder is needed.
- **A request that failed**: the bar says why ("The list did not accept the request: ...") with "Try Again".
- **No close button and no setting**: the bar is one line, shown only on list mail. If it proves noisy, a Reading setting can come later.

## The look on each platform

The same place and words; each platform's own idiom:

- **Windows**: the Outlook Express band across the reading pane under the header, as the pictures bar, with a classic push button at its right (part 2 gives every Windows bar this form).
- **The Mac**: the reader's info bar (as the pictures and Try Again bars) with a small push button, as Mail's own "This message is from a mailing list" bar.
- **Linux**: an `AdwBanner`, libadwaita's bar for exactly this: a title and one button.

## The work

1. **Core**: on the message view, the bar's state (`none`, `offered`, `requested`, `opened`, `came_after`, `failed`), its words and its button's label, already put together, so the apps compute nothing (`pe-core/src/unsubscribe.rs`, the C API's message info, the header regenerated). The domain rule above as a pure function. A migration (a new entry in `MIGRATIONS`) with a table `unsubscribed (account, list, method, at)`, its key the account and the list; written when a one-click request is accepted, when the draft the bar opened is sent (the draft carries the list it is for, and the Outbox writes the row once the server took the message), or when the page is opened; agent requests go through the same function. An event when a row is written, so every open view of that list redraws its bar. The command `unsubscribe` in `core/commands.toml`, enabled by the state. The folder rule (not in Junk E-mail, Sent Items, Drafts) in the core, for the bar and for the command alike.
2. **The three apps**: the bar in the reading pane and message windows, the link removed from the header, the menu entries, the verb buttons on the Mac and Linux. Status bar text stays as it is.
3. **Help**: `unsubscribe.html` in every language describes the bar, the menu command, the remembered state and the two-day rule (marked for review).
4. **The bars' order** in each reader: download failed, pictures blocked, mailing list, each a row of its own that takes no height when hidden.

# Part 2: the other link actions

## What the screenshots show

| Action                                                | Windows                                                                | The Mac                              | Linux                             |
| ----------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------ | --------------------------------- |
| Clear search (the search results bar)                 | link                                                                   | link                                 | flat button                       |
| Create Rule... (the search results bar)               | link                                                                   | button                               | flat button                       |
| Pictures blocked bar                                  | whole bar clickable, "Click here to download them", arrow for its menu | whole bar clickable, same words      | Download Pictures button and menu |
| Download failed bar                                   | whole bar clickable, "Click here to try again."                        | Try Again button                     | Try Again button                  |
| More sign-in options... (Add Mail Account)            | link                                                                   | link                                 | flat button                       |
| Import settings and accounts from another computer... | link                                                                   | link                                 | flat button                       |
| How to connect an agent (AI Agents)                   | link, "How to connect an agent"                                        | button, "How to Connect an Agent..." | button                            |
| Why? (Add Mail Account, a sign-in turned off)         | link                                                                   | link                                 | link                              |

The problems: the same action is a link on one platform and a button on another; a link says "this takes you somewhere", yet these start something (clear a search, make a rule, download, sign in, import); a click-anywhere bar is not visibly a control, and its "Click here" wording does not work for a keyboard or a screen reader; links on Windows are owner-drawn buttons or `SS_NOTIFY` statics that the app has to make reachable by Tab itself (`KeyboardLink`).

## Decided

| Question            | Answer (2026-11-21)                                                                                                                                                                                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Why?                | Stays a link on all three: it only explains, as Apple's and GNOME's "Learn more" links do. The one deliberate link in the app's own windows                                                                                                                                                |
| The bars on Windows | The Outlook Express band and color stay; the "Click here..." wording goes and each bar gets a classic push button at its right: Download Pictures (with its menu arrow as a split part), Try Again, and Unsubscribe... of part 1                                                           |
| Add Mail Account    | "More sign-in options..." a push button under the provider buttons; "Import settings and accounts from another computer..." moves to the left end of the dialog's button row (Windows: left of Next and Cancel; the Mac: beside the ? button). Linux keeps its flat buttons where they are |

## Defaults chosen (say if you want otherwise)

- **The search results bar**: Create Rule... and Clear Search are push buttons on Windows (small, in the yellow bar) and the Mac (as its Create Rule... already is). Linux keeps its flat buttons. Clear Search with title-case capitals, as a button label.
- **The pictures bar on the Mac** gets a Download Pictures button and the menu beside it, as Linux has; the bar itself stops being clickable. The wording becomes the Linux one, without "Click here" (one string for all three: `ui-pictures-blocked` reworded, `gtk-pictures-blocked` removed).
- **The download failed bar on Windows**: the note and a Try Again button; `win-click-to-retry` removed.
- **AI Agents on Windows**: a push button "How to Connect an Agent..." at the left of the button row, the words of the Mac and Linux.
- **Windows' own link drawing** (`CreateLinkButton`, `DrawLinkButton`, `KeyboardLink`, the link font) stays only for Why?; what no longer uses it is removed.

## The work

1. **Strings**: reworded pictures text without "Click here", `ui-download-pictures` shared by all three, Clear Search as a button label, the removed Windows-only strings; every language marked for review.
2. **Windows**: push buttons in the search results bar, the pictures bar (button plus split arrow) and the download failed bar; Add Mail Account's two buttons; AI Agents' button; the bars' layout measured so a long translation shortens the text, never the button.
3. **The Mac**: Clear Search and the Add Mail Account buttons; the pictures bar's button and menu.
4. **Help**: the topics that name these (pictures, search, adding an account, agents) say "click Download Pictures", "click Clear Search" and so on, in every language.
5. **Keyboard and screen readers**: every new button is a Tab stop in reading order with its label as its accessible name; the bars' text is read with them. On Windows the buttons take part in the dialog's or pane's Tab order as ordinary buttons, which is what lets `KeyboardLink` go.

# Tests

Every new function gets a test where it is written, and each pull request's description lists what is covered by which test and what is checked by hand.

## Part 1

**Unit tests (core)**

- The domain shown: the confirmed signer for one-click; List-Id's host; the sender's host; a List-Id with a display phrase (the phrase is never shown); an invalid or overlong host, a host with spaces, control characters, right to left marks or a lookalike in non-ASCII letters (shown as `xn--` or not at all).
- Each state and its words: offered; requested (one-click accepted); opened (web page); a failed request with its reason; a message that arrived before the request, within two days of it, and after (with times given to the function, no clock in the test).
- The folder rule: no bar and no command in Junk E-mail, Sent Items and Drafts; both in the Inbox, Archive and a search of all folders, by the message's own folder.
- The store: the migration on a store of the release before; one row a list and account, a second request replacing the date; the row gone with its account; `kept_check.rs` still passes.
- The key: List-Id compared without case; no List-Id falls back to the From address; two accounts on the same list are separate.
- Agents: an agent's approved request writes the same row; an agent can still not unsubscribe in Junk E-mail; the limits (30 in 24 hours) are unchanged.

**End to end, the core against ImapKit** (`e2e_core.rs` has `unsubscribes_with_one_click` with a local HTTP endpoint; `e2e_ffi.rs` for the C API)

- One click: the request is posted, the row is written, the message's state reads requested, a second message of the list synced afterwards reads requested too, and the event arrives.
- The endpoint answers 500: the state is failed with the reason, no row; Try Again with the endpoint mended succeeds.
- By mail: the draft from the bar, sent through ImapKit's SMTP, writes the row only once the server accepted it; a draft closed unsent writes none.
- A list message put in Junk E-mail offers nothing, through the C API too.

**End to end, the three apps** (`SCENARIO.md` step 24, each platform's UI test, `feature-map.mjs`)

- The bar is there with its domain and button; the header has no link; the Message menu and the right-click menu have "Unsubscribe...", disabled on a message that is no list's.
- The question has Unsubscribe and Cancel on the Mac and Linux, Yes and No on Windows; Cancel changes nothing.
- After Unsubscribe: the endpoint got the request (asked over ImapKit's REST API and the test's own listener), the bar says when, the button is gone, the menu command is disabled; another message of the same list shows the same.
- A list message with blocked pictures shows both bars in order; a message window shows the bar too.
- Step 28 (agents, `agents-7-unsubscribe`): after the agent's approved request the message's bar says it was asked.
- On the Mac and Linux, whose tests run in the app's process, the remembered date is moved back three days and a new list message shows "came after" with "Unsubscribe again...". Windows' test drives the windows from outside and can not move the date, so there the rule is covered by the core's tests only; the PR says so.
- Screenshots `read-8-unsubscribe`, `read-9-unsubscribe-ask`, `read-10-unsubscribe-requested`, `read-11-two-bars`, in light and dark where the tests take both, each reviewed.

## Part 2

No logic changes, so the tests are the apps' own:

- Each UI test presses the new buttons by their ids (Clear Search, Create Rule..., Download Pictures and its menu, Try Again, More sign-in options..., Import..., How to Connect an Agent...) where it clicked links and bars before, and checks the same outcomes as today (the search ends; the rule window opens with the search's words; pictures load and the bar goes; the message downloads; the sign-in list opens; the import starts; the help topic opens).
- Each test walks the Tab order of Add Mail Account and of the reading pane's bars and checks the buttons are reached, with their names.
- `feature-map.mjs` entries updated where a screenshot's name or feature changes; `--check` passes on each platform.
- The catalogs: `check-language.mjs` and the core's catalog tests over every language (removed keys gone everywhere, the new ones present, access keys unique in their scopes: the new buttons in Add Mail Account need letters that are free in every language).
- The help tests (`cargo test -p pe-html -- --include-ignored`): every `data-text` a topic names still exists.
- Screenshots `read-2-pictures`, the search bar's, `account-1-form`, `agents-6-window`, the failed download's, reviewed on all three, with the longest languages (German, Finnish, Greek) checked in the language tour so the bars' buttons are never cut.

# How it is done

Two pull requests on all three platforms: part 1, then part 2. Both merge before the translations of `languages-wave2-plan.md` (its PR 3), so the new languages translate the final words once.

**Before each commit**, in this order, with what they find fixed:

1. `/simplify`, with a look at the functions that grew (each reader's layout of bars; `unsubscribe.rs`). Part 2 should remove more than it adds on Windows (the link drawing).
2. `/security-review`, and the work goes on in the same turn afterwards. What it looks at: part 1, that nothing a sender wrote reaches the bar but a validated host name; that the one-click request is still sent only for a provider-confirmed signature and only after the user's yes; that the menu command and the bar go through the same question and can not skip it; that the folder rule holds through the C API and for agents; that the new table tells an agent nothing it could not read before. Part 2, that the buttons call exactly what the links called, with no new path to loading pictures or signing in.
3. `cargo fmt`, clippy with `-D warnings`, prettier on Markdown and YAML; the generated files (`inbox_classic.h`, the commands of the three apps) committed with the change.
4. The test suites: `cargo test --workspace` on the Mac, `scripts/win-test.sh`, `scripts/linux-test.sh`; the three UI tests with `feature-map.mjs --check`.

**After each push**: CI watched to the end (fmt, clippy, generated files, tests on three systems, the three apps' builds and UI tests, `check-shells.sh`, which wants `app/`, `mac/` and `linux/` changed with the new command); a real failure fixed and pushed, a flaky one rerun at most three times. Every screenshot goes through the UX review loop: read, fixed and read again until nothing is left. The new and changed strings are marked for review in every language.

# What the review corrected

- The bar shows a domain, never the List-Id's name: sender-chosen words do not belong in the app's own bar.
- "Still arriving" is decided from each message's own arrival, with no search for later messages.
- An e-mail request is remembered when the Outbox has sent the draft the bar opened, not by matching sent mail against links.
- Hiding it in Junk E-mail is a change from today, not existing behaviour.
- Added: the bars' stacking order, keyboard and screen reader checks, the tests by layer, and what each /security-review looks at.
