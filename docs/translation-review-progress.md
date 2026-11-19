# English and translation review, round 3

## Resume here

- Authoritative checkout: `/Users/andris/Projects/PostalExpress/build/i18n-english-originals-20261119`; branch `i18n/english-originals-20261119`.
- All 1,483 English catalog entries and 53 English help topics have been read against their app context. All affected meanings were compared across the 28 translations. The exact coverage and retained-content decisions are in the state and sealed review artifacts.
- Corrected 93 English catalog values and 51 English help topics; corrected 469 translated catalog values and 609 translated help topics (980 changed help lines).
- Three English MCP response literals now distinguish eligibility checks and partial Undo from guaranteed restoration. No runtime logic or schema keys changed.
- Review complete. REVIEWED is `bf44141a12811e63e7e9f3c8302345c7a16d57cc`; baseline check reports zero pending messages, help passages or unmarked changes. Publication/merge is authorized and pending. Starting source: `c00d1cb0560ed3e54324208d04f36ba671ac3fa1`; freshly fetched master matches it.

## Validation and limits

All 1,711 catalog/help file hashes match their parent snapshots and final review receipts. All 174 catalogs parse without syntax errors. The 28 language checkers report only their expected 1,536 draft-marker notices each; no structural findings remain. All 65 mnemonic scopes pass in each of the 29 languages, including English. Help tags, attributes and literal keys/code are preserved, except the recorded English Mac Control qualifier needed for the actual shortcut.

The required offline pe-ffi build passed, including pe-mcp. Generated installer and Linux store metadata were checked against all catalog values; the desktop file and sign-in resources did not change. The MCP file passes rustfmt for the repository's 2024 edition. No local test suites, CI queries, manually triggered workflows or release actions were performed, as requested. This is a context and structural review, not native-speaker approval or GUI layout certification.

## Material corrections

Requests, scheduled operations and confirmed results now remain distinct. Corrections cover partial Undo, unsubscribing, attachment requests, draft removal on queueing, provider sign-in guidance, local-data removal, encryption and identity claims, cache and preview limits, search behavior, platform instructions and image permissions. Good translations that already included the relevant qualifications were retained.

Round 2 remains archived in `translation-review-round2-state.json` and `translation-review-round2-progress.md`. Its English findings were historical evidence: this round rechecked them against current source rather than assuming they still applied. In particular, the current English delete-and-undo topic already included the absent-Trash condition and was retained.

## Completion evidence

The exact review receipts and validation artifacts are preserved at `/Users/andris/Projects/PostalExpress/build/i18n-english-originals-completed-20261119`. The active state and progress are also archived as `translation-review-round3-state.json` and `translation-review-round3-progress.md`.
