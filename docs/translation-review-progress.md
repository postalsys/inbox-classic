# Translation review, round 6

## Completed review

- Authoritative checkout: `/Users/andris/Projects/PostalExpress/build/i18n-pr244-review-20261122`, branch `i18n/pr244-review-20261122`.
- PR #244 merged at `d42951a569eaf1313da6312ae5127da0bda1a2dd`; local master was synced. Latest audited upstream is `f66af7cb6e9a0ba65a008f1885179a4b8a8ebdef`.
- Linguistic review is finished. English and affected strings/help in the original 28 translations were reviewed against app callers. Japanese, Simplified Chinese, Traditional Chinese, Korean, Indonesian and Vietnamese received full reviews: 8,940 catalog entries and 318 help topics.
- Current inventory: 35 languages including English, each with 1,490 catalog entries and 53 help topics. No review marks or unresolved language passages remain.
- Final replay accounts for all 2,065 catalog/help files, including 499 changed catalog values and 415 changed help topics compared with the latest upstream. Historical review hashes remain preserved; the state records final hashes and superseding followups.
- Corrections cover mailing-list request/history wording, agent permissions, plaintext/TLS/DNS scope, CJK search, key ownership versus signature integrity, forwarding prefixes and account import. Context-menu Unsubscribe has its own access key. Help strips complete CJK mnemonic suffixes and full-width field colons.
- Validation: 210 Fluent catalogs parse; 34 language checkers have zero structural findings after accounting for 52,462 expected removed-mark diagnostics; all 35 × 67 modeled mnemonic scopes are clear. All 5,565 platform help documents are balanced and references valid. Offline pe-ffi/help-export builds and all three platform exports passed. Generated installer and Linux metadata are included.
- Round 6 is complete and archived. `REVIEWED` is `cc96034650ebb623dad6fb4f5b7a806971d75e52`. The final check reports zero pending messages, zero pending help passages and zero unmarked changes. Latest audited upstream is integrated. Published in [PR #252](https://github.com/postalsys/inbox-classic/pull/252); there is no remaining language-review queue.
- Evidence: `/Users/andris/Projects/PostalExpress/build/i18n-pr244-monitor`. Full new-language ledgers and exact followup ledgers are retained there; final coverage and quality reports reconcile them.

## Validation policy

No local test suites, CI queries or manually triggered workflows. Static checks, caller inspection and offline builds only. No native-speaker certification, native GUI fit check or Windows keyboard-runtime certification is claimed.
