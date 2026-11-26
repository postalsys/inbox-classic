# Translation review, round 8

## Resume here

- Authoritative checkout: `/Users/andris/Projects/PostalExpress`, branch `master`.
- Round complete. Reviewed content commit and current baseline: `44bd9b2d33db99329a587683ad6061fbcfa7bee7`. No pending entries or topics.
- Starting local and fetched origin/master: `69b9897538d8fb9e0acd37fc1f7958c4704454b3`. The READY handoff confirmed all strings were merged.
- Previous reviewed baseline: `af31d1c03fc18cd3df8ed7e7ce708dfb148a2be8`; advanced only after all languages and late changes were covered.
- User authorized current repository glossary/help-writing guidance in place of the missing Downloads guide, parallel language work, and committing/pushing master.
- No tests, builds, native GUI checks or CI queries. Static translation checks and caller inspection only.

## Completed review

Reviewed 113 English catalog entries and 10 complete English help topics. Corrected 10 English values and 6 topics
through 36 exact edits. Independent cross-review confirmed runtime claims and added the initial conversation-view
qualifier. All target languages match frozen English revision 4.

Reviewed all 34 translations in parallel: 3,842 catalog entries and 340 complete help topics, covering 714 initially
marked passages. Corrected 462 catalog values and 235 help topics; retained good wording. Every queued ID/topic is
recorded, all initial snapshots match the starting Git commit, all final ledger hashes match the files, and there
are no unresolved entries or remaining marks. Glossary notes record the wording and access-key decisions.

The main corrections clarify sync conflict history and secret exclusions, local-only mail, setup steps, conversation
printing and selection, platform keyboard behavior, and reaction counts/notifications/domain checks. No app logic changed.

## Static verification

- Fluent parser and catalog completeness: 35 languages, 210 catalogs, 56,525 messages; all registered languages present.
- Help: 1,925 topics, checked as 5,775 platform-specific documents; references and markup valid.
- All 2,695 modeled mnemonic scopes clear (77 per language).
- All 34 language checkers have exactly 1,670 expected removed-draft-mark diagnostics each and zero structural findings.
- The 560 historical reference/literal differences exactly match the previous review; no new differences.
- Exact ledger coverage, comments, unchanged catalog values, source hashes and `git diff --check` pass.

These are static checks and contextual editing, not native-speaker approval or runtime testing.

## Evidence

State: `docs/translation-review-state.json`. Detailed snapshots, canonical per-language ledgers, independent English
review, final static report, HTML review and late-arrival evidence are under
`build/i18n-round8-monitor-20261125`. Build artifacts are not committed. The tracked state records exact reviewed IDs,
full topics, final file hashes, evidence hashes and the source baseline for resuming or auditing this round.

## Completion

The reviewed content is committed on master and REVIEWED points to that concrete commit. The final baseline check
reports zero pending catalog entries, zero pending help passages and zero unmarked changes. No tests or builds were
run. This record is archived as round 8. The authorized final publication step pushes the content and completion
commits to origin/master, then records the matching local/remote commit in the local publication evidence.
