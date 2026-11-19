# Tests that stay green

Every CI failure from 2026-11-10 on that was not a real bug came from one of a few habits: a test that checked how
the core did something rather than what came of it, a fixed time budget on a slow shared runner, a wait that an event
of an earlier step answered, a comparison with English words, or a test that went to the internet without saying so.
These rules keep them out, in the Rust tests and in the UI tests of all three apps.

## The rules

1. **Check what the user or the caller gets.** The message listed, the flag on the server, the text the window shows,
   the order two things came in: not which session the server sees in which state, how many events of a kind came, or
   which worker did it. An outcome stays the same when the core gets faster or does its work in another order.
2. **Wait on a real event, with a generous budget.** A wait ends as soon as what it waits for comes, so a long budget
   costs a passing test nothing; a short one fails a busy runner. Rust tests wait up to `pe_testkit::patience()` (60
   seconds, `PE_TEST_PATIENCE` to change it). Never `sleep` and then assert: wait for the state instead.
3. **Assert speed only where speed is the feature**, and then as an order where possible: the flag reached the server
   before the slow upload finished, the small message was ready before the large one. Make the slow part far slower
   (seconds, through an ImapKit script rule) than the fast part can ever take. A measured time is for the speed tests
   (`list_speed.rs`, the "within seconds" of a dead connection), with a budget for the slowest runner.
4. **Never let a leftover event answer a wait.** Events that come again and again (`FolderChanged`, `RulesApplied`,
   `SyncFinished`) may belong to an earlier step, to IDLE or to the background worker. Wait for what the step changes
   (`Setup::wait_until`), match the step's own payload (its request number, its UID), or drain the events before the
   step (`Setup::drain`, `drain` in the C API tests).
5. **Compare with the catalog, not with English.** Text the core makes comes from `pe_core::i18n::tr(Text::...)` (or
   `tr_args`), so a test compares with that, and with `pe_core::sentence` where the C API makes a sentence of it. A
   change of wording, or a run in another language, then fails no test.
6. **No internet unless `PE_NETWORK_TESTS` is set.** Servers, OAuth issuers and key directories are played on
   loopback: ImapKit (with its OAuth provider for sign-in), or a listener in the test. A test that must reach the
   internet checks `PE_NETWORK_TESTS=1` and returns otherwise.
7. **A flake that is a race in the core is fixed in the core.** If a click can queue behind other work in a test, it
   can in the app: fix the routing, then test the outcome.
8. **No blanket retries.** Not of tests, not of CI jobs, and no loops that run a step again until it passes. A step is
   tried again only where the app itself does so (a connection the server dropped before reading it).

## Examples

### Rust (`pe-core`, `pe-ffi`, `pe-mcp`)

```rust
// the message in the list, not a FolderChanged that the first sync or IDLE may have told already
s.core.sync(second).unwrap();
s.wait_until(|| subjects().len() == 2, "the new message listed");

// the order is the feature: the large download waits at the server, aimed at its UID
s.server.request("POST", "/v1/script/rules", Some(json!({
    "on": "command", "match": format!("UID FETCH {big} .*BODY\\.PEEK\\[\\]"), "delay": 15000, "times": 1
})));
s.core.open_message(inbox, big).unwrap();
s.core.open_message(inbox, small).unwrap();
let first = s.wait(|e| *e == ready(small) || *e == ready(big));
assert_eq!(first, ready(small));

// the catalog's words
assert_eq!(text(reason), pe_core::sentence(&tr(Text::SignInAppIssuerChanged)));

// the events of the syncs before are not this step's
s.drain();
s.core.apply_rule_now(rule).unwrap();
```

The core gives tests exact signals where an outcome can not be seen from outside: `Core::reader_ready` says the
reader waits with a connection of its own, in place of guessing the reader's session from ImapKit's list.

### Windows (`scripts/ui-e2e.ps1`)

```powershell
# the outcome on the server, waited for with room for a slow runner (WaitFor ends as soon as it holds)
$sent = WaitFor { Messages 'INBOX' | Where-Object { [int]$_.uid -gt $before } | Select-Object -First 1 } 60
Check ($null -ne $sent) 'the reply reached the server'

# the words of the catalog the app shows, not English
$words = Catalog 'en'
Check ((WindowText $button) -eq $words['ui-undo-button']) 'the status bar offers Undo'
```

### Mac (`mac/Sources/InboxClassic/UITest*.swift`)

```swift
// wait for what the window shows, then compare with the catalog's text
let shown = await waitUntil(60) { undoSendButton.isHidden == false }
check(shown && undoSendButton.title == Text.uiUndoButton.text, "the status bar offers Undo")
```

### Linux (`linux/src/e2e.rs`)

```rust
// wait_until lets the list settle before it looks; a generous budget, the catalog's text
let shown = wait_until(60, || text_of(&root, "undo-send") == pe_core::i18n::tr(Text::UiUndoButton)).await;
check(shown, "the status bar offers Undo");
```
