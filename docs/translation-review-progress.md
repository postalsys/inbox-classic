# Developer-correction re-review, round 4

## Resume here

- Authoritative worktree: `/Users/andris/Projects/PostalExpress/build/i18n-developer-followup-20261119`, branch `i18n/developer-followup-20261119`.
- Source and final upstream checkpoint: `a3ac000103b217077a4a054697cbe67db05e1d68` (PR #222). No upstream additions arrived during the review. No unmerged-source discovery was performed.
- All requested content is reviewed and statically validated. Next: commit it, advance REVIEWED to that concrete commit, verify the final baseline, archive this round and publish under existing authorization.
- Previous completed round 3 is preserved in `translation-review-round3-state.json` and `translation-review-round3-progress.md`.

## Coverage and result

- Rechecked the changed English message `pgp-part-other` and 12 affected English help passages across 11 topics against current callers. This is a targeted follow-up to the earlier full English review.
- Reviewed 28 translated catalog entries and 336 marked help passages across 308 translated topics in all 28 target languages. All marks were removed only after the exact passages were reviewed.
- Changed all 28 catalog values and 288 help passages across 261 translated topics; retained 48 already accurate help passages. Corrected one additional English help line. Mark removal alone is not counted as a wording change.
- Signature identity, encrypted-draft scope, unsubscribe account selection, print behavior, ignored-message handling, folder error feedback and shortcut instructions now match the verified actions.
- The Mac renderer now includes Control, so obsolete manual Control additions were removed. Print instructions have Windows preview and Mac/Linux print-dialog branches. Notification instructions include the four localized special-folder labels.
- Additional English defect fixed: Properties displays Internet headers, not message size, on all three platforms. The translated instructions now say so too.
- Preserved supported manual attachment preview actions and the accurate MCP bulk-flag Undo caveat. Their omission from simplified English help does not establish that those actions are impossible.

## Validation

- Reconciled all 1,711 catalog/help file hashes against the frozen source snapshot and four disjoint review ledgers. All changes are accounted for; translated bytes outside the original marked passages are unchanged.
- All 174 Fluent catalogs parse. All 28 language checkers have zero structural findings after separating their 1,536 expected draft-marker notices per language.
- All 65 mnemonic scopes in each of 29 locales are clear. Changed HTML balances on Windows, Mac and Linux; literal keys/code, IDs, placeholders and unrelated markup are preserved. Intentional markup changes are recorded.
- Offline `cargo build -p pe-ffi --offline` passed, including pe-mcp. No tracked generated outputs changed. `git diff --check` passed.
- The pre-baseline `--since` audit finds no additional waiting content; its 316 unmarked changes correspond exactly to the 28 changed catalog values and 288 changed translated help lines.
- No local test suites, CI queries or manually triggered workflows. No GUI fit or native-speaker certification is claimed.

## Separate runtime follow-up

On Mac and Linux, a mailto unsubscribe opened from a separate message window can use the main window's current account if that window has switched accounts. The normal message-reader path uses the containing account, and Windows passes the separate message's account explicitly. This is a static caller finding, not a GUI reproduction. Runtime code was not changed in this translation round. Evidence: Mac `MessageWindow.swift:144` and `MainWindow.swift:479`; Linux `reader.rs:1352`, `app.rs:570` and `mailbox.rs:960`; Windows `messagewindow.cpp:231`.

## Evidence

Frozen ledgers and the full source snapshot are in `/private/tmp/inbox-developer-followup-20261119-*`. The final verified archive will be at `/Users/andris/Projects/PostalExpress/build/i18n-developer-followup-completed-20261119`. State records contain exact per-file coverage, before/after hashes, validation and the previous-round links.
