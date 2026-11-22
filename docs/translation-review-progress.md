# Mailing-list bar and late-arrival review, round 6

## Resume here

- Authoritative checkout: `/Users/andris/Projects/PostalExpress/build/i18n-pr244-review-20261122`, branch `i18n/pr244-review-20261122`.
- PR #244 merged at `d42951a569eaf1313da6312ae5127da0bda1a2dd`; local master was synced.
- Completed its 252 marked catalog entries and 168 marked help passages across the original 28 target languages, plus English, the new context-menu label in all 29 languages, and affected neighboring unsubscribe/agent help. There are 154 changed catalog values including 29 new labels, and 58 changed help topics.
- Static checks: 174 catalogs parse; all 28 language structural checks pass after accounting for draft-mark assumptions; 67 Windows menu/dialog scopes per language have no key collisions. Linux/macOS context labels strip mnemonic marks. Offline pe-ffi build passed; generated C/Swift text IDs included. No test suites or CI queries.
- Late upstream arrival: master `7668e552b45bd4db5fe3067617eac2ead13f8b05` now includes Japanese, Simplified and Traditional Chinese, Korean, Indonesian and Vietnamese, plus action-button/search help changes. These require integration, exact inventory and review next. This round is incomplete.
- Keep `REVIEWED` at `a040e21e1f2955f1cc9ce37962ce74280d05e672`. Previous round 5 is archived. Evidence is in `build/i18n-pr244-monitor` of the root checkout.

## Validation policy

No local test suites, CI queries or manually triggered workflows. Static checks, caller inspection and offline builds only. No native-speaker certification or GUI fit claim.
