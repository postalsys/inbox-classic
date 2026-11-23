# Translation review, round 7

## Resume here

- Authoritative checkout: `/Users/andris/Projects/PostalExpress`, branch `master`.
- Started at `f5470316c0aa06cf1a4b53d7e9be16432026df4b`; previous reviewed baseline `cc96034650ebb623dad6fb4f5b7a806971d75e52`. Round 6 remains archived.
- English and all 34 translations are reviewed. Added 408 translations for the English-only PGP/sender-check features, corrected 19 neighboring shortcut labels, and reviewed 68 target help pages. English received 10 copy corrections across two catalog values and two full help topics.
- Corrections distinguish public-key upload from confirmed address listing, key lookup from verified ownership, private-key attachment rejection from import, and later key expiry from signature validity. Sender-check help names both default domains and background rechecking after synchronization.
- Final provenance covers all 2,065 catalog/help files and all 476 target queue items: 429 changed catalog values and 70 changed help topics including English; zero uncovered changes or pending items.
- Current inventory: 35 languages including English, each with 1,502 catalog entries and 53 help topics.
- Static checks: all 210 catalogs parse; all 34 language checkers have zero structural findings after accounting for 52,870 expected removed-mark diagnostics. All 2,345 modeled mnemonic scope instances are clear; all 5,565 platform help variants are balanced and references valid. Historical contextual literal/reference differences are preserved and documented.
- Offline pe-ffi/help-export builds and Windows/macOS/Linux help exports passed. Final generated-output and rendered-label evidence is kept with the review records.
- Next: commit to local master, update the reviewed baseline, verify zero pending/unmarked changes and archive round 7. Do not push or create a PR.
- Evidence: `/Users/andris/Projects/PostalExpress/build/i18n-round7-20261123`. Frozen language ledgers, original snapshots, source followups, final hashes and independent coverage reports are preserved there.

## Validation policy

No local test suites, CI queries or manually triggered workflows. Static checks, caller inspection and offline builds only. No native-speaker or native GUI certification is claimed.
