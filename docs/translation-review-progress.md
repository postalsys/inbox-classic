# Code-change follow-up review, round 5

## Resume here

- Authoritative worktree: `/Users/andris/Projects/PostalExpress/build/i18n-code-followup-20261121`, branch `i18n/code-followup-20261121`.
- Starting and final upstream checkpoint: `fa016a57c0149783b910a5a3197b7362262eac9b`. Prior round 4 remains archived and was merged in PR #223 at `36351eb2209264d74286335b905653c756e09894`.
- All requested content is reviewed and validated. Next: commit content, advance REVIEWED, verify the final baseline, archive and publish under existing authorization.
- No unmerged-source discovery. Local master-only commit `347e720e8bcecd40b579f82bdd2b5edcccfbe9e4` changes screenshot cropping, with no string/help meaning impact; it remains outside this publication branch.

## Coverage and corrections

- Reviewed and corrected three English help passages: connections, read-messages and main-window. The runtime review covered the relevant changed code and neighboring English context; it does not claim a new full-corpus fluency review.
- Reviewed 84 translated passages across all 28 target languages. Corrected 75; retained nine accurate connections paragraphs. Removed only the reviewed marks. Catalog values are unchanged since the prior reviewed content.
- Started with 55 marked passages. Reopened one unmarked Estonian connections paragraph because its English source changed, plus 28 unmarked main-window startup paragraphs found stale by the runtime review.
- Sign-in-code help describes provider-supplied Authentication-Results or ARC-Authentication-Results and the required valid DKIM signature from the code's domain or a parent. It does not imply ARC-chain verification or restrict Microsoft to one header form.
- Folder navigation selects the last viewed message or its conversation when still listed, otherwise the newest message or its conversation. A collapsed conversation displays its first message. This distinction was checked through actual row construction and reading-pane callers on all three platforms.
- Startup restores the saved folder or combined view; first Inbox/All Inboxes is the fallback. Existing dynamic controls and markup are preserved.
- The remaining runtime-diff review found no additional stale product wording. Duplicate-copy Undo, pending flags, list/selection fixes and Mac menu additions fit existing descriptions.

## Validation

- Reconciled all 1,711 catalog/help files against the prior review, current Git source, exact reopened spans, final content snapshot and four frozen ledgers. No content outside the reviewed target spans changed.
- All 174 unchanged Fluent catalogs parse. All 28 language checkers have zero structural findings after separating their 1,536 expected draft-marker notices per language.
- All 65 mnemonic scopes in each of 29 locales are clear. Changed HTML balances on Windows, Mac and Linux; tags, dynamic labels, literal keys/code, IDs and placeholders are preserved. No structural exceptions.
- Offline `cargo build -p pe-ffi --offline` passed, including pe-mcp. No tracked generated output changed. `git diff --check` passed.
- The pre-baseline `--since` audit has no additional waiting content; its 84 unmarked values correspond exactly to the reviewed target passages against the previous REVIEWED commit.
- No local test suites, CI queries or manually triggered workflows. No native-speaker certification or GUI fit claim.

## Separate recorded follow-up

The previously reported Mac/Linux standalone-window mailto unsubscribe account-selection issue remains in unchanged caller bodies. The main window's current account can be used after it switches accounts; Windows passes the standalone message's account explicitly. It is a static caller finding, not a GUI reproduction or a new regression. Runtime code is unchanged in this round. Current references are recorded in the runtime ledger and state.

The connections review also identified stale internal BIMI/sender-picture comments about provider headers. Those comments are not product strings and were recorded without broadening this translation change.

## Evidence

Exact before/after text, hashes, language decisions, source/caller evidence, broader runtime audit and validation artifacts are in `/private/tmp/inbox-code-followup-20261121-*`. The final verified archive will be at `/Users/andris/Projects/PostalExpress/build/i18n-code-followup-completed-20261121`. Round-4 records remain unchanged.
