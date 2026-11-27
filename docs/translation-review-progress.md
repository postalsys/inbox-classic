# Translation review, round 9

## Resume here

- Authoritative checkout: `/Users/andris/Projects/PostalExpress`, branch `master`.
- Review and static validation complete. Content/baseline commits and the zero-pending baseline check remain.
- Starting local and fetched origin/master: `c135330965efb301008b51dd99f539ee89687465`.
- Previous reviewed baseline: `44bd9b2d33db99329a587683ad6061fbcfa7bee7`; advance only after the reviewed content commit exists.
- User authorized English and translation editing in parallel, committing to master, and explicitly **no push**.
- Current repository glossary and help-writing rules remain the authorized guidance. No tests, builds, native GUI checks or CI queries.

## Completed review

Reviewed 13 new English labels, the reopened setting note and the full conversation help topic. Corrected one
English catalog value and one full topic through 12 exact edits, including an independent cross-review. English
revision 3 is frozen; the new button labels and count messages were retained.

Reviewed all 34 translations in parallel: 442 new catalog entries, 34 reopened setting notes and one adjacent Latvian
menu label, totaling 477 entries, plus 34 complete help topics. Corrected 42 catalog values and all 34 topics.
Together with English, the review covers 491 entries and 35 topics, with 43 corrected catalog values.

The changes distinguish selecting from folding a message, grouped folded rows, draft-specific buttons, sender
summaries, platform menu availability, keyboard focus and protected-message pictures. Finnish folding wording,
Korean spacing, action-label capitalization and Latvian ASCII access keys are corrected. Good new translations are
retained. Current glossary guidance replaces the old 20-message explanation. No app logic changed.

Every queued entry/topic and the Latvian neighbor are recorded. Initial snapshots match the starting commit; final
ledgers, English sources and runtime references match the files. No unresolved entries or remaining review marks.
The late-arrival audit found no new files, languages or upstream changes. All pre-baseline unmarked differences are
accounted for by exact completed scope; the reviewed baseline remains unchanged until the content commit.

## Static verification

- 35 registered languages, 210 catalogs and 56,910 messages (1,626 per language); Fluent syntax and completeness pass.
- 1,925 help topics checked as 5,775 platform-specific documents; markup and references pass.
- All 2,730 modeled access-key scopes pass (78 per language), including the new frame More menu.
- All 34 language checkers report exactly 1,681 expected removed-draft-mark diagnostics each, with zero structural findings.
- The 560 historical help-reference/literal differences exactly match round 8; no new differences.
- Exact ledger coverage, unchanged entries/comments, source hashes and whole-worktree diff checks pass.

These are static checks and contextual editing, not native-speaker approval or runtime testing.

## Evidence

The tracked state records exact IDs/topics, final file hashes and evidence hashes. Detailed snapshots, per-language
ledgers, source cross-review, final static report, HTML review and late-arrival audit are in
`build/i18n-round9-20261127`; generated evidence is not committed. Round 8 remains archived separately.
