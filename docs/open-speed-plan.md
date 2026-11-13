# Opening messages without waiting: plan

A new message shows up in the list, the user clicks it, and the reading pane shows the spinner for a long time. This plan
says where that time goes, what other mail clients do about it, and the changes that make opening a message instant in
the common case and quick in the rest.

## What happens now

1. The list shows the new message: the main worker's IDLE on the Inbox woke, `sync_one` stored the summary (envelope,
   flags, size). The message body is not downloaded.
2. The user selects it. Every app shows the header from the list row at once and calls `open_message`
   (`pe-core/src/lib.rs:1105`), which sends `FetchSource` to the account's **reader**: a second worker with an IMAP
   connection of its own, so opening never waits for a sync (`worker.rs` `read`).
3. The reader downloads the whole message (`BODY.PEEK[]`, attachments included) with `fetch_source`, writes it to the
   store, then sends `MessageReady`; the app asks for the view, built on a worker thread.

The split into a main worker and a reader is already the right shape. The time goes elsewhere:

| #   | Cause                                                                                                                                                                                                                                                                                             | Where                                               | Cost                                                                                                                                                                                                      |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **No body is downloaded before the click.** Every first open of a message is a network round trip, whatever its size.                                                                                                                                                                             | `pe-sync` stores summaries only; nothing prefetches | 0.3 to 2 s at best, every time                                                                                                                                                                            |
| 2   | **The reader's connection goes stale.** It is opened at the first click and then sits unused, with no NOOP, no IDLE and no TCP keepalive. Servers close idle connections (RFC 3501 allows it after 30 minutes), routers and NAT forget them sooner, and a laptop that slept has lost all of them. | `worker.rs` `client`, `pe-net/src/stream.rs:122`    | A closed one: a failed command, then connect, TLS, sign-in, SELECT, FETCH again (1 to 3 s). A silently dead one: **up to 300 s**, the response timeout (`pe-imap/src/client/mod.rs:65`), before the retry |
| 3   | **The first click after start connects from nothing.** The reader connects lazily.                                                                                                                                                                                                                | `worker.rs` `client`                                | TLS, sign-in (an OAuth token refresh too, at times), SELECT: 0.5 to 2 s                                                                                                                                   |
| 4   | **A large message is shown only once all of it is here.** A 15 MB message with a PDF shows nothing until the PDF is downloaded.                                                                                                                                                                   | `fetch_source`                                      | Seconds to minutes on a slow line                                                                                                                                                                         |
| 5   | **One click waits for the one before.** The reader skips requests it has not started, but a download under way finishes first. Clicking past a large message waits for it.                                                                                                                        | `worker.rs` `read`                                  | As long as the large download                                                                                                                                                                             |
| 6   | **Background downloads hold the main worker.** It fetches text for the search (`index_texts`, 50 messages a batch, up to 64 KB of text each) and References for conversations whenever no command waits, batch after batch, and looks only at its commands between them.                          | `worker.rs` `run` (the two `while` loops)           | Bandwidth on slow lines; a move, delete or flag waits for the batch under way; **the Inbox is not watched and server events are not applied until the whole backlog is done**, so new mail shows late     |
| 7   | **The store is written before the view is built.** `set_source` and the search row are written before `MessageReady`; a write the main worker holds makes it wait (busy timeout 5 s).                                                                                                             | `fetch_for_view`                                    | Usually milliseconds, at worst seconds                                                                                                                                                                    |

Related defects found on the way:

- `code_of_new` (`worker.rs:1347`) wraps `fetch_source` on the **main** connection in a 5 second timeout. When it runs
  out the FETCH is dropped halfway, and the connection is left with the rest of the response unread. It also downloads
  the newest message whatever its size.
- Each worker is one task, and `index_text` parses the message inside it. A message that makes the parser panic ends the
  account's worker. Today that needs the user to open the message; once mail is downloaded ahead it would happen by
  itself, at every start.
- A batch of `index_texts` that fails is tried again after the next command, for ever, when the failure is one message's.
- A message the user moves loses its downloaded source (`remove_messages` removes it with the row), and is downloaded
  again in the folder it went to.

## What other mail clients do

- **Apple Mail** downloads new messages in full as they arrive, attachments too by default, so opening reads from disk.
- **Thunderbird** keeps IMAP messages on the computer by default ("synchronize for offline use") and downloads new
  messages' bodies in the background after it gets their headers. It keeps several connections to a server (5 by
  default) so the message the user opens does not wait for a folder's sync. For a large message it is not keeping, it
  fetches only the parts it shows first (MIME parts on demand) and the attachments when they are opened, and it renders
  as the message streams in, in chunks.
- **Outlook** in cached mode keeps a local copy of the mailbox and syncs in the background; the user works on the local
  copy.
- **Mobile clients** (Gmail, K-9 Mail and Thunderbird for Android, Apple Mail on iOS) download recent messages up to a
  size limit, and the rest of a large one only when it is opened.
- **Gmail and Fastmail on the web** load the messages near the one on screen, so the next one opens at once, and show
  every action at once and send it to the server after.

What they share:

1. **The body is usually on the computer before the click.** Prefetching new mail is the main reason they feel instant.
2. **The user's request jumps the queue.** A connection that is never busy with background work; background work that
   steps aside while the user waits.
3. **Connections are kept warm and checked**, and dropped at once after sleep or a change of network.
4. **What can be shown is shown first**: the header at once, the text before the attachments.
5. **Neighbors are fetched ahead**, because the next click is usually Next or the row below.

## Connections

An account has one connection it can not do without, and others it uses when the server gives them:

| Connection    | For                                                                | Lives                                    | Without it                                                                         |
| ------------- | ------------------------------------------------------------------ | ---------------------------------------- | ---------------------------------------------------------------------------------- |
| Main          | IDLE on the Inbox, syncs, the user's commands (move, delete, flag) | Always                                   | The account is offline                                                             |
| Reader        | The message the user opens                                         | Always, from start (phase 2)             | Opens go to the main worker, ahead of everything but the command under way         |
| Background    | Downloading ahead, the search text, References                     | While there is such work, then 5 minutes | The work runs on the main worker, in small batches between its commands and events |
| Second reader | A click while a large download is under way                        | On demand, 5 idle minutes                | The click waits for the download, as now                                           |
| Upload        | Saving a draft, the copy in Sent Items (APPEND)                    | One upload, then closed                  | The upload runs on the main worker, as now                                         |

- **Every connection but the main one is tried and done without when it fails**: the server refuses it (too many
  connections, `[LIMIT]`, `[UNAVAILABLE]`, a BYE at sign-in) or it can not be made while the main one works. The work
  falls back as the table says, and nothing is reported to the user. The core remembers the refusal and tries that
  connection again after 15 minutes, not at every click.
- **One connection is enough for everything.** An account whose server allows a single connection works as the app does
  today, with the main worker's background loop repaired (below).
- At most five at once, usually three (Gmail allows 15 per account, Dovecot 10 per address by default). The upload and
  the second reader are short.
- The fallback for background work is the repaired loop of the main worker: one small batch, then the server's events
  applied and the Inbox looked at, then the next, and none while a command or an open waits.

## The plan

Each phase is useful on its own; the order is by how much waiting it removes for the work it takes. Everything is in the
core (`pe-core`, `pe-sync`, `pe-imap`, `pe-net`), so all three apps get it at once; the apps change only in the settings
(phase 3) and the waiting state (phases 5 and 6).

### Phase 1: measure

Without numbers, the rest is guessing at which cause the user sees most.

- A timing record for every open, in the core: queued, connect, sign-in, SELECT, first byte, last byte, store write,
  view built, with the message size, which connection served it (none: from the store; reader; main) and whether that
  connection was new, reused or retried.
- Kept in memory for the last 200 opens (`Core::open_timings`, `pe-core/src/timing.rs`) and written to the standard
  error when an open takes more than 1 s or fails (the core has no log file; no message content, only times, sizes and
  the server's host). With them, **the share of opens served from the store**: the number phase 3 is there to raise.
- `cargo run -p pe-core --example open-timing -- [latency ms] [--dead]` against ImapKit behind a proxy that adds
  latency (and, with `--dead`, stops answering on the connections it has), to compare before and after each phase.

### Phase 2: a reader that is always ready (causes 2, 3)

Core only: no change to the C API or the apps.

- **Connect the reader at start**, after the main worker's first sync, not at the first click. Refused: opens go to the
  main worker (see Connections).
- **Keep it alive**: TCP keepalive on every socket (`socket2`: idle 60 s, interval 15 s, 4 probes where the system
  lets it be set) keeps NAT and routers from forgetting a quiet connection, and a NOOP every 15 minutes while the
  reader waits keeps servers from logging it out (they may after 30). **A NOOP that fails replaces the connection at
  once**, so it is ready again before the next click and not found dead by it.
- **A short limit for the first byte of what the user waits for**: on a connection the reader had already, no data
  within 8 s (3 s when the connection was quiet for more than a minute) and the reader drops the connection and tries
  once more on a new one, without that limit (a connection made just now is alive). The FETCH itself is the check: no
  NOOP is sent before it. The reader's sign-in and reads have 30 s at most; the 300 s inactivity limit stays for the
  main worker and background work.
- **Sleep**: the core notices a wake by itself: a 30 s tick whose wall clock moved more than 90 s. Every connection
  made before it is then dropped when next used (each remembers the wake it was made after), the main worker leaves
  IDLE without DONE and syncs the Inbox, the reader connects again. `Core::woke` does the same, for an app that hears
  of a network change. The same works on all three systems with no code in the apps.
- **Network changes** are covered by keepalive and the first byte limit. The apps telling the core (`NotifyAddrChange`,
  `NWPathMonitor`, `GNetworkMonitor`) is added later only if phase 1's numbers still show waits after a change of
  network.
- Fix `code_of_new`: the time limit around the whole FETCH goes. Until phase 3 it fetches only a message under the
  download limit, on the reader, with the first byte limit; from phase 3 on it reads the source the store already has.

### Phase 3: the message is here before the click (cause 1, and 6)

- **The background worker**: a third `Role`, with a connection of its own while it has work (see Connections). It takes
  over the main worker's two loops (`thread_stored`, `index_texts`) and the downloading ahead. The main worker goes back
  to IDLE after every command.
- **The main worker's loop repaired**, for when there is no background connection: one batch at a time, the server's
  events applied and the Inbox's new mail synced between batches.
- **New mail is downloaded as it arrives.** After a sync stores new messages, the main worker tells the background
  worker, which fetches their sources, newest first, those under the size limit. The notification does not wait for
  it: only the newest message's source is waited for, for its one-time code, with the first byte limit.
- **Batches by bytes, not by count**: about 512 KB a FETCH, read message by message (`fetch_each`), each written to the
  store in a transaction of its own, so nothing large is held in memory and the store is never locked for long.
- **Which folders**: every folder's but Junk E-mail, Deleted Items and Gmail's All Mail (whose messages are the other
  folders' again). Those download when opened.
- **The search text comes with it.** For a message that is downloaded ahead (recent, under the limit, in such a
  folder), the whole source is fetched and indexed as an opened message is. For the rest, and when the setting is "Only
  when opened", `index_texts` fetches the text parts as it does now.
- **The neighbors of the message opened.** After the reader has the message the user asked for, and no other click
  waits, it fetches the one above and the one below it in its folder by date (Next and Previous, the arrow keys, in the
  list's usual order), if the setting downloads them ahead, they are under its size and not here. The apps do not
  change: the core has no list view of theirs to read.
- **A moved message keeps its source**: for a move the app made, the server's COPYUID says which message in the target
  folder it became, and the source goes with it. Never matched by Message-ID, which the sender chooses.
- **A message that can not be had is passed over**: its parsing runs where a panic is caught (`spawn_blocking`, or
  `catch_unwind`), and a message whose download or parsing failed is marked and not tried again in the background (a
  new column, a migration). Opening it still tries.
- **A setting for the whole app**, in Settings on the Mac, Preferences on Linux (a "Downloading" group) and Options on
  Windows (a section under a line):
    - "Download messages ahead: [Recent messages up to 1 MB | All messages | Only when opened]". Default: recent
      messages (the last 30 days) up to 1 MB.
    - "Downloaded messages kept for each account: [250 MB | 500 MB | 1 GB | 2 GB | 5 GB | 10 GB]", 1 GB to begin with.
    - Kept in the store's app settings, as `pictures.always` is (`download.ahead`, `download.limit_mb`), with C API
      getters and setters for Windows and the Mac (`pe_download_ahead`, `pe_download_limit_index`, and the choices'
      words from `pe_download_limit_text`).
- **The storage limit wins, and the oldest mail goes first**:
    - Past the limit, the sources of an account's oldest messages (by date) are removed, never those of Drafts and the
      Outbox, nor a message opened since the app started. They download again when opened.
    - Downloading ahead goes newest first and stops at the first message older than the oldest one kept once the limit
      is reached, so it never downloads what would be removed next. "All messages" means all that fit.
    - The size kept is counted from a column of the row (`length(source)` once, in a migration), not by reading the
      sources.
- **Words and help**: the new strings in every catalog (non-English marked `# review: new`), the topic on settings in
  every language, the step in `scripts/ui-e2e/SCENARIO.md` and its entry in `scripts/feature-map.mjs`.

### Phase 4: the user goes first (causes 5, 6, 7)

- **A second reader connection.** When a click comes while the reader downloads a message over 256 KB, the click goes
  to a second reader (made on demand, its connection closed after 5 idle minutes) instead of waiting. The first
  download finishes and is kept. Refused: the click waits, as before.
- **Background work steps aside.** A shared count of opens under way (`worker::Opening`). The background worker
  waits before each batch while it is above zero, so the line is the user's. Text batches are of 16 messages (about
  1 MB at most), so a move, delete or flag the main worker does in their place starts within a moment.
- **Uploads on a connection of their own.** Saving a draft, the copy in Sent Items (APPEND, often megabytes) and
  removing the drafts of a message sent go to the account's uploader: a worker of its own fed by a queue, its
  connection closed after 5 idle minutes. The main worker hands an upload over and stays on the Inbox and the user's
  commands; it syncs the folder after. The queue keeps the order (drafts are removed after a save of theirs). When
  the uploader can not connect, it hands each upload back to the main worker, which does it as before. An upload that
  failed is told and not repeated (the next save of a draft replaces it by its Message-ID).
- **The view first, the store after**: not built. Phase 1's numbers show the window told 1 to 10 ms after the last
  byte, the store write included.

### Phase 5: large messages show their text first (cause 4)

- For a message over 1 MB that is not here, the reader fetches its structure (`BODYSTRUCTURE`), its header, every
  part's MIME header and the content of the parts that are no attachment (the text, the HTML, the pictures shown in
  it), by the rules of the parser (`BodyStructure::attachments`). It puts them together as a message the view reads as
  the whole one, its attachments named but without content and their sizes from the structure, and shows it
  (`MessageReady`). That is held in memory, never stored (`pe-sync/src/text_first.rs`, `worker/large.rs`).
- The whole source follows in one FETCH; pe-imap tells how many bytes came (`Client::on_received`), and the status
  bar says how far it is every megabyte ("Downloading 4.2 MB of 15.0 MB"), then "Downloaded 15.0 MB" once it is
  stored. Save As, View Source, Forward and the attachments read the store, so they work once it is all here; an
  attachment opened before says the rest is still downloading.

### Phase 6: what the user sees while waiting

- The pane already shows the header from the list at once, and the downloading page after 250 ms, on all three
  platforms. That page now says how large the message is ("The message is 2.3 MB. It will appear here once it is
  downloaded."), from the first moment it shows rather than after a second.
- The UI tests check that a new message downloaded ahead opens from the store, with no download, by the core's record
  of the open (`pe_last_open_from_store`; on Windows through a test hook).

## Tests

- **pe-imap**: the first byte limit, a connection that answers nothing (the e2e test's `SilentServer`), TCP keepalive
  set on the socket.
- **pe-store**: the migrations; the storage limit removes the oldest sources and keeps Drafts, the Outbox and what was
  opened; a moved message keeps its source.
- **pe-core with ImapKit**:
    - New mail arrives over IDLE and its source is in the store without an open.
    - Messages over the limit, and those of Junk E-mail, Deleted Items and All Mail, are not downloaded ahead.
    - Downloading ahead stops at the storage limit and does not download what it then removes.
    - The neighbors are fetched after an open.
    - New mail shows in the list while a backlog is downloaded, with a background connection and without one.
    - A reader whose connection was cut opens the next message within the first byte limit plus a connect; after a
      failed NOOP the reader is connected again before the next open.
    - A server that allows one connection: opens, background work, a draft and a sent copy all go over the main one
      (ImapKit with a connection limit, or the test's own server that refuses a second sign-in), and the refused
      connections are not tried again at once.
    - A second click during a large download is answered first.
    - Background batches wait while an open is under way.
    - A draft is saved over a connection of its own while the main worker stays in IDLE.
    - A message whose parsing panics is passed over, and the worker goes on.
- **The UI tests of all three apps**: a new message opens from the store; after the connection is cut (ImapKit's REST
  API closes the session), the next open still succeeds; the new setting in each app's Settings or Options.
- **The timing example** before and after, with the numbers in the pull request.

## Order of work

| Phase           | Size            | What it removes                                                            |
| --------------- | --------------- | -------------------------------------------------------------------------- |
| 1 Measure       | Small           | Guessing                                                                   |
| 2 Ready reader  | Small to medium | The long waits: stale connections, the first click                         |
| 3 Prefetch      | Large           | The round trip on most opens; new mail showing late behind background work |
| 4 User first    | Medium          | Waits behind large downloads, background work and uploads                  |
| 5 Text first    | Large           | Long waits for large messages                                              |
| 6 Waiting state | Small           | Waiting that says nothing                                                  |

All six phases are built, in this order, one pull request each. Phases 1 to 3 cover what the user sees most often.
Phase 3 may be split in two pull requests if it grows too large to review: the background worker with the repaired
loop first, the downloading ahead with its setting second.

## How each phase lands

Each phase is one branch and one pull request off an up-to-date `master`, merged only when CI is green:

1. The core and its tests first, then the C API and the three apps where the phase touches them, then the UI tests,
   `SCENARIO.md`, `feature-map.mjs` and the help.
2. Locally: `cargo fmt`, `cargo clippy --workspace --all-targets`, `cargo test --workspace`, the Linux checks
   (`scripts/linux-test.sh`), and the UI tests of the apps the phase changes (`scripts/linux-ui-e2e.sh`,
   `scripts/mac-ui-e2e.sh`, `scripts/win-ui-e2e.sh`). The timing example before and after, its numbers in the pull
   request.
3. **/simplify** on the diff, its findings applied.
4. **/security-review** on the diff, its findings fixed. Phases 3 and 5 get particular attention: what is downloaded
   ahead is untrusted mail stored and parsed without the user opening it, and partial sources must never be mistaken
   for whole ones (Save As, View Source, Forward, the attachments).
5. Prettier on the changed Markdown and YAML; `node scripts/i18n-review.mjs --check` where words changed.
6. Commit, push, open the pull request, watch CI. A failure from a real problem is fixed and pushed again; a flaky one
   is rerun, at most three times.
7. Merged when CI is green, then the next phase starts from the new `master`.

A release is not part of this plan; it is cut when asked.

## Decided

1. **Downloading ahead**: recent messages (the last 30 days) up to 1 MB by default.
2. **Storage**: a limit the user sets, applied to each account (1 GB to start). The limit wins over downloading ahead,
   and the oldest mail's sources go first.
3. **Phase 5**: built now, as part of this plan, by parts (`BODYSTRUCTURE`), not by byte ranges.
4. **The setting**: one for the whole app, not per account.
5. **Pull requests**: one per phase, merged when CI passes.
6. **Connections**: a background connection, a second reader and a short-lived upload connection are each tried and
   done without when the server refuses them; one connection is always enough.
7. **Folders downloaded ahead**: all but Junk E-mail, Deleted Items and Gmail's All Mail.
