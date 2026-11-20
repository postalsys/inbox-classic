# The deep test: the apps on mailboxes the size people have

Written 2026-11-20, after 0.19.1. The overview with pictures is `docs/deep-test-overview.html`; the journeys are in `scripts/ui-e2e/DEEP.md`.

## The incident

0.19.0 shipped a Linux list that went blank in large folders: Flagged, then Inbox, and the rows were empty and opened nothing (#226). The list keeps 8 pages of 100 rows. GTK reads every row of a list that is replaced, so a folder of more than 800 messages asked for all its pages at once, the first ones were pushed out, and nothing asked for them again.

No test saw it, for four reasons that each name a gap:

- **Scale in the windows.** The UI tests' folders hold 4 to 30 messages, so no list had a second page. `list_speed.rs` has 229,000 messages but calls the core, and the core was right. Each app keeps its own pages between the core and the screen (Windows 8 pages of 100 too), and nothing tests those.
- **Sequences.** It took a list replaced while another was shown. The user's words were "eventually all folders are empty". The regular scenario does each thing once, from a known state.
- **A continuous comparison.** Each step checks what it just did. Nothing asks after every step whether the window still shows what the server has.
- **One toolkit's habit.** The Mac and Windows read only the rows in sight. A check on one platform says little about another.

## Decided

1. **One conductor, three small drivers.** The world, the journeys, the walk and the checks are written once, in Rust. Each app's UI test learns a short vocabulary of actions and one "say what the window shows". The same run drives the core without a window.
2. **Journeys and a walk.** Named journeys for each family of risk, and a random walk with a seed.
3. **About 34,000 messages in 5 accounts, about 30 minutes a platform.** A larger overnight profile is another seed and step count, not other code.
4. **`release.sh` refuses without a passing deep run of the commit**, as it does for translations; `ALLOW_NO_DEEP=1` releases anyway, with a warning.
5. **The gate starts per platform**, from the pull request that gives the platform a driver (Linux first). Platforms without one are skipped with a note.
6. **The core walk runs weekly on GitHub** with a new seed, not a gate, as the OpenPGP interoperability suite does.
7. **The runs a release reads happen on GitHub's runners**, in a workflow started by hand. Local runs stay possible on all three.

It never runs on a pull request.

## Where the same kind of bug can hide

| Family                            | Situations                                                                                                                                                                                           |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pages and what is kept            | more pages than kept; the last, partial page; folders of exactly 100, 800, 801; rows read far from the screen (End, Page Down held, the scroll bar dragged, type to find)                            |
| Answers that come late            | a page of the folder before arrives after the switch; the sort changed while a page is on its way; a search typed fast, then cleared; folders clicked faster than their lists come                   |
| The list changes under the window | new mail while scrolled to the middle; another client deletes the rows on screen or the selected one; the count shrinks below the scroll position; a folder emptied, renamed or deleted; UIDVALIDITY |
| Selection across pages            | Select All of 5,000 then delete, move, flag, mark read; Shift ranges over pages not loaded; the selection through a sync; Undo; a move the server refuses half way                                   |
| Views of many folders             | All Inboxes, All Sent, All Drafts, Flagged over the accounts; one account off line or with a wrong password; an account removed while its rows are listed; "by account" on and off                   |
| Conversations                     | a conversation of 300; one expanded at a page boundary; one across folders; Watch and Ignore; conversations switched on and off in a big folder                                                      |
| Finding                           | thousands of hits, paged; a search while the text is still fetched; every operator against the server's truth; a search in All Inboxes                                                               |
| The first sync and restarts       | the list usable while 20,000 messages arrive; counts that only go up; quit in the middle and start again; the same folder, row and scroll position after a restart                                   |
| The connection                    | dropped in the middle of a batch; one slow command; extra connections refused; IDLE through the run; the queue while off line                                                                        |
| Rules, agents, bulk commands      | a rule run on 5,000; Empty Folder of 10,000; Mark All Read; an agent's bulk move with the window on that folder                                                                                      |
| The folder tree                   | 400 folders nested deep; names in other scripts; every folder's counts against the server after every step                                                                                           |
| Slow growth                       | memory, open files, connections and the store's size over the run; windows opened and closed hundreds of times                                                                                       |

## The parts

### The world (`pe-testkit` `world`)

A generator with a seed (the `Rng` that is there): accounts as ImapKit users on one ImapKit, folder trees, messages with real shapes (conversations by Message-ID and References, attachments, flags, dates over years, other scripts and charsets, signed and encrypted mail, bounces, invitations, a few of 40 MB). Built once into an ImapKit snapshot (`/v1/snapshot`), kept under `build/deep/` by seed and generator version, loaded in seconds. The same seed gives the same world everywhere; a test says so.

| Account    | Messages | Shape                                                                        |
| ---------- | -------- | ---------------------------------------------------------------------------- |
| Work       | 20,000   | an Inbox of 18,000, 60 folders, long conversations                           |
| Home       | 6,000    | 400 folders nested 6 deep, names in other scripts                            |
| Gmail-like | 5,000    | signed in through ImapKit's OAuth provider, All Mail, labels                 |
| Lists      | 3,000    | newsletters, bounces, invitations, encrypted mail, huge messages             |
| Broken     | 200      | slow, drops connections, refuses a second one, its password changed half way |

If ImapKit lacks something (a snapshot of several users, a fault we need), we add it to ImapKit; it is ours.

### The checks

One set, compared with the server over ImapKit's REST API, after every step once the app is quiet, in the words of `docs/testing.md` (outcomes, real waits, the catalog's text, no retries):

- the list has as many rows as the server has messages for that view (a folder, a unified view, a search);
- no row in sight is blank, and the rows in sight are the server's, in the sort order;
- the selected row's message is the one in the reading pane;
- every folder's total and unread count match the server, and no message is listed twice;
- nothing the window shows belongs to a folder left behind.

"Quiet" needs a real signal, not a sleep: the core says when no command, sync or page is on its way (to be added to the core's test surface if what is there does not say it). Some checks hold even before quiet: rows of another folder are never shown, and a blank row in sight gets its text within the patience.

### The conductor (`pe-deep`)

A binary in the core's workspace, never linked into an app. It loads the world, starts a target, runs the journeys and the walk, runs the checks, samples health and writes the report.

Targets: `core` (calls `pe-core` as the C API does, no window) and the three apps through their drivers.

**The walk** draws steps from a weighted table of what a user does (folder, scroll, sort, search, select, open, delete, move, flag, mark, reply, send, switch account, settings that redraw lists) and what a server does (new mail, another client's flags, moves and expunges, a folder renamed, a dropped connection, a slow command through ImapKit's script rules). Stretches of "fast fingers" send several actions before anything has come back, then wait for quiet and check. It keeps a model of what the user did, so a deleted message is expected in Deleted Items.

A failure prints the seed and the step. `--seed S --until N` plays it again; the conductor then tries shorter prefixes to give the smallest run that still fails. Seeds that once failed are kept in `core/crates/pe-deep/seeds.txt` and run every time, before the new seed.

Timing differs between runs even with one seed; that is why checks wait for quiet, and why a failure's report holds the window's and the server's answers and not only the seed.

### The drivers

A driver reads lines and answers lines over the test's standard input and output:

```
> folder work/Inbox
> scroll 4200
> observe
< rows 18044 first 4188 blank 0 selected - pane -
```

About 30 actions and `observe` (the folder shown, the row count, the rows in sight with their text, the selection, the reading pane's subject, the tree's counts, the status bar, bars over the list). They do what a user's hand does (a click on a row, a key), not calls into the core.

They live where the UI tests live: Linux in `linux/src/e2e/` behind the `e2e` feature, the Mac in the in-process test host (`UITest*.swift`), Windows in PowerShell outside the exe (`scripts/ui-e2e/`), which reads the list as the regular test does. A release build gets no port, pipe or test command. The security review of each driver's pull request checks that.

### Health

Resident memory, open files or handles, IMAP connections (ImapKit's `/v1/sessions`) and the store's size, sampled through the walk. Judged as growth between the first and the last third of the run, with wide margins, so a slow runner fails nothing.

### Running it

- `scripts/deep-test.sh core|linux|mac|windows|all [--seed S] [--steps N] [--until N] [--profile overnight]`.
- `.github/workflows/deep.yml`: started by hand for a commit (the three apps and the core), weekly for the core walk. It records its result on the commit.
- `release.sh` asks GitHub for a passing deep run of the tag's commit, for the platforms that have a driver, before any build and for `PLATFORMS=` reruns too. So the order of a release becomes: merge the release pull request, start the deep run on the tag while CI runs, then `release.sh`.

A run leaves a page like the feature map (`build/deep/<platform>/report.html`, an artifact on GitHub): the journeys with pass or fail, the walk as a timeline with its seed, the health curves, and for a failure the last 30 steps, a screenshot, both answers and a copy of the store.

**What a failure becomes.** Every bug the deep test finds is fixed with a small, fixed step in the regular scenario, as 27a was for this incident. The deep test finds, the regular test keeps.

## The order of work

Each step is a pull request. Before each commit: `/simplify` (with the look at the functions that grew), `/security-review`, prettier, the tests; then CI watched to the end. Bugs found on the way get pull requests of their own, with their step in `SCENARIO.md`.

1. **The plan and the catalog.** This file, the overview, `DEEP.md`.
2. **The world.** The generator, several users, the snapshot, the test that a seed gives one world. Whatever ImapKit needs first, in ImapKit.
3. **The conductor on the core.** The checks, the table, the walk, replay and shrinking, `seeds.txt`, `scripts/deep-test.sh core`, the weekly workflow.
4. **Linux's driver and the journeys.** Proof first: with 0.19.0's list model the walk must find the blank list by itself, and the journey of pages must fail. The hand-started workflow; `release.sh` asks for Linux's run.
5. **The Mac's driver.** `release.sh` asks for its run too.
6. **Windows' driver**, on GitHub's runner. `release.sh` asks for all three.
7. **Faults and a second client** in the walk, and the Broken account.
8. **Health, the report page, the docs** (`docs/testing.md`, `CLAUDE.md`, `docs/shells.md`).

## Checks

- The same seed gives the same world, byte for byte, on the Mac, Linux and Windows.
- On 0.19.0's `linux/src/messages.rs` the journey of pages fails and the walk finds the blank list within its standard steps. A deep test that can not find the bug it was built after is not done.
- A bug put in on purpose in each family's code (a page not asked for again, a count not updated, a late answer shown) is found; these are tried by hand once per family when its journey is written, not kept.
- The core target and a window target with one seed do the same steps.
- A release build of each app contains nothing of the drivers (`strings`, the feature list, the exe's command line).
- One platform's standard run stays near 30 minutes on GitHub's runners.
