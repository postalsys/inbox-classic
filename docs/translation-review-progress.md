# Translation review, round 11

## Resume here

Authoritative checkout: `/Users/andris/Projects/PostalExpress`, local `master`.
**Round 11 is complete.** Reviewed content is committed in `cacbccffec3f43c0d02636785b56b148d071796d`.
REVIEWED points to that commit. The final check reports zero pending and zero unaccounted translation changes.
This round is archived in `translation-review-round11-state.json` and `translation-review-round11-progress.md`. **Do not push.** No tests, builds, GUI runs or CI checks.
Starting commit: `117580f3bc744d123c35b4499df2d059b18dddc3`. Previous reviewed baseline: `82a928b66c7309c3068f9f7438d43e6ed85d4d8b`.
Round 10 is complete and archived. Current repository guidance was explicitly authorized by the user.

## Reviewed changes

Reviewed all **38 new or changed English catalog entries** and improved four values. Added **1,292 translations**
across all **34 target languages**. Also corrected the existing Russian `reader-failed-network` message to cover
interrupted connections, with its matching help quotation. Target review: **1,293 catalog entries/values**.

Reviewed two complete help topics per language (`no-connection` and `password-not-accepted`): **70 full-topic reviews**
including English. Also reviewed and changed the exact conversation View menu paragraph in each language:
**35 paragraph reviews**, without claiming another full-topic review. All 105 affected help files changed.

The account-status feature distinguishes a rejected sign-in from a connection or TLS failure. The wording explains
administrator approval, IMAP access, wrong browser accounts and stale mail without inflecting arbitrary names.
The compose connection warning now makes Outbox waiting conditional on sending failure, because outgoing mail may
still connect independently. The help avoids a universal expiry period, a lockout-prevention guarantee and stale
dialog quotations. Source evidence and decisions are recorded in the state and English ledger.

PR #275 has merged: the existing conversation View menu instructions now appear on Windows as well as Mac/Linux.
The selected-message wording from round 10 is preserved. Glossary guidance reflects the current behavior.

Three reviewers processed language groups in parallel; the parent reviewed English and took over Greek for the final
batch. All 35 exact language ledgers are authenticated against the final English revision (3), with no unresolved
passages. No application code or generated sources were changed.

## Validation

All **2,135 catalog/help files** are accounted for. Each of 35 languages has **1,663 catalog IDs and 55 help topics**;
there are no missing messages/topics or pending review marks. The Fluent parser and all 34 static language checkers
have zero structural findings. Each checker reports only 1,718 expected missing-draft-mark diagnostics for already
reviewed content. All **2,730 menu/dialog mnemonic scopes** pass (78 per language).

The help audit checked **5,775 platform-specific help variants** for markup, references, platform branches and literal keys.
The 560 historical source/translation reference or literal differences are unchanged; no new differences appeared.
The late source refresh still matches `117580f3bc744d123c35b4499df2d059b18dddc3`, and all unreviewed files are unchanged.
Static checks and contextual editing do not constitute native-speaker approval.

Evidence is in the ignored `build/i18n-round11-20261128/` directory: exact language ledgers, `final-quality-audit.json`,
`late-arrival-audit.json`, source hashes and the review inventory. The final baseline check passed. No pending work remains in this round.

All review changes are committed on local master. Nothing was pushed by this review session.
