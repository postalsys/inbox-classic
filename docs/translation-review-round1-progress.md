# Translation review, November 2026

Objective: make the translations read as natural UI and help text in each language, using the actual application
behavior and surrounding controls to establish meaning. Preserve the original scope across sessions.

## Completed review

- Starting checkout: `27616ee9` on `master`; initial review baseline: `94577d0`.
- Read `/Users/andris/Downloads/inbox-classic-translation-guide.md`, `core/locales/GLOSSARY.md`, and
  `core/crates/pe-html/help/FORMAT.md` before continuing.
- `translation-review-state.json` lists the exact pending catalog IDs and help pages. Completed batches record
  their reviewed files and content hashes. Check `git log` and `git status` before using this record: new work may
  have landed since the last batch. Review any subsequent source or translation changes as well.
- Initial inventory: 241 marked messages and 14 marked help passages per language (de, es, et, fr), 964 messages
  and 56 help passages altogether. Each language has ten affected help pages. Other languages named in the guide
  are not present in this checkout. `scripts/check-language.mjs` is also absent here.
- All four translation sets and the final English/source consistency pass are complete.
- Review baseline: `7c0b1672581c9bd7a33c226f35da16cedca4b528`. `--check` passes with zero pending drafts or unmarked changes.
- No pending work remains from this review. For new changes, compare against the recorded file/source hashes.

## Checkpoint rules

- Work in small, completed batches and commit only the reviewed language's files and these progress records
  (plus glossary changes when needed). Never include `build/` or unrelated user files.
- Follow the supplied guide: remove review marks only after checking the complete message or help passage.
  Retain uncertain entries and record the reason. Do not advance `REVIEWED` during partial review.
- The current review checker compares unmarked text to a single old baseline; it will report reviewed entries
  as unmarked during this round. Match these reports to the completed batch inventory. After every language is
  finished, commit the reviewed state, advance `REVIEWED` to that commit, then require a clean review check.
- Check catalog syntax, IDs, placeholder sets, plural behavior, access keys in their actual menus, and help
  structure. Run `cargo test -p pe-i18n -p pe-html` from `core` for completed batches. Refresh
  `build/i18n-review.html`; this generated file is not committed.
- Preserve the unrelated untracked feedback, language-planning and responsiveness documents in `docs/`.

## Completed batches

### et-app-2026-11-16

Reviewed all 94 marked entries in `core/locales/et/app.ftl`, including encryption-key management, attachment
actions and settings transfer. Removed their review marks. Corrected formal address, awkward literal wording,
address-list grammar, key verification instructions, and access-key collisions. Added Estonian terminology notes
to the glossary. 32 values were improved; the remaining labels were retained after review.

Validation: all 68 `pe-i18n`/`pe-html` tests passed; IDs, placeholders, plural branches, access-key presence and
new-dialog shortcut uniqueness passed; `git diff --check` passed. The 94 removed marks are intentional.

Checkpoint commit: `150faf9e`.

### et-core-2026-11-16

Reviewed all 143 marked core messages and the four marked entries in `help.ftl`, `linux.ftl` and `mac.ftl`.
Improved 71 core values: formal address, signature versus key-owner verification, natural error/result wording,
address lists, filenames without inflected placeholders, and settings-transfer terminology. The attachment notice
now accurately describes cleanup at startup of temporary copies older than a day. Review marks removed;
all 68 tests and catalog invariant checks passed. All 241 unmarked catalog entries exactly match the two
completed batches; there are no untracked omissions.

Checkpoint commit: `2e34851e`.

### et-help-2026-11-16

Reviewed all 14 marked passages across the ten pending Estonian help pages. Rewrote the new key management,
verification, encrypted-mail and migration topics; corrected attachments and folder/account navigation text.
Formal address, terms and control names now match the catalogs. Removed the review marks. All help tags, links,
control references and platform branches are preserved. All 68 tests and `git diff --check` passed. The tracker
accounts for all 241 unmarked catalog entries and 69 unmarked help lines. The review HTML was regenerated;
723 messages and 42 help passages remain in the other languages.

Checkpoint commit: `f596775a`.

### de-app-2026-11-16

Reviewed the 94 marked German UI messages and the shared Remove button (95 entries in the batch). Improved 31
values, including literal key/verification instructions, settings transfer, the All Sent label and shortcuts.
The extra Remove mnemonic avoids collisions with Properties and Export in the new key window and Accounts.
IDs, placeholders, plural branches and mnemonic presence are preserved. Dialog and new menu shortcut checks
pass; all 68 tests and `git diff --check` passed.

Checkpoint commit: `6c6cc9ac`.

### de-core-2026-11-16

Reviewed all 143 marked core messages and four platform/help labels. Improved 60 core values, including
key-owner verification, encryption errors, filenames, account credentials and export/import results. The
attachment notice now describes cleanup at startup of copies older than a day. Removed all German catalog
review marks. All 68 tests, catalog invariants and `git diff --check` passed.

Checkpoint commit: `d3ea269f`.

### de-help-2026-11-16

Reviewed all 14 marked passages across ten German help pages. Rewrote key management, fingerprint verification,
encrypted-mail and migration explanations. Corrected attachment cleanup, folder navigation, hidden unread counts
and the order of verification steps. All tags, links, control references, platform branches and keyboard names
are preserved. All 68 tests and `git diff --check` passed; the inventory accounts for every unmarked change
(483 catalog entries and 141 help lines). Regenerated `build/i18n-review.html`.

Checkpoint commit: `c088888d`.

### es-app-2026-11-16

Reviewed all 94 marked Spanish UI messages and improved 28 values. Replaced literal key-management and
verification phrasing, clarified saved credentials and signing in again, and standardized backup/export
protection as "contraseña". Added the terminology decisions to the glossary. All 68 tests, catalog invariants,
dialog/menu shortcut checks and `git diff --check` passed.

Checkpoint commit: `ca9d02b0`.

### es-core-2026-11-16

Reviewed all 143 core messages and four platform/help labels; improved 63 core values. Clarified private-key
errors, address lists, key discovery, stored credentials, import results, missing rule folders and temporary
attachment cleanup. Removed all Spanish catalog review marks. All 68 tests, catalog invariants and
`git diff --check` passed.

Checkpoint commit: `fd172449`.

### es-help-2026-11-16

Reviewed all 14 marked passages across ten Spanish help pages. Rewrote the new encryption, verification and
migration topics; corrected attachment handling, combined folder views and unread counts. Preserved all tags,
links, control references, platform branches and keyboard names. All 68 tests and `git diff --check` passed;
724 unmarked catalog entries and 210 help lines match the completed inventory. All completed file/source
hashes match. Regenerated `build/i18n-review.html`.

Checkpoint commit: `209fe6e2`.

### fr-app-2026-11-16

Reviewed all 94 marked French UI messages; improved 24 values. Rewrote literal key-management and verification
phrasing, clarified transferred credentials, and fixed three shortcut collisions. All 68 tests, catalog
invariants, dialog/menu mnemonic checks and `git diff --check` passed.

Checkpoint commit: `91355d31`.

### fr-core-2026-11-16

Reviewed all 143 core messages and four platform/help labels; improved 62 core values. Reworked literal errors
and import results, clarified key protection and stored credentials, and corrected French singular-category
counts so zero cannot appear as one. All 68 tests, catalog invariants and `git diff --check` passed.

Checkpoint commit: `74078651`.

### fr-help-2026-11-16

Reviewed all 14 marked passages across ten French help pages. Rewrote new topics and corrected attachment
handling, folder layout, hidden unread counts and verification order. Preserved all tags, links, control
references, platform branches and keyboard names. All 68 tests and `git diff --check` passed; all 965 unmarked
catalog entries and 279 help lines match the completed inventory. File/source hashes match. The regenerated
review HTML has no remaining marked drafts.

Checkpoint commit: `3deaae10`.

### Final consistency pass

All 965 catalog entries (the original 964 plus the shared German Remove button) and all 40 affected translated
help pages are reviewed. In total, 372 translated catalog values were improved. Every pending list is empty.
Five English catalog values and eight English help topics were corrected to match the application. The final
cross-language checks cover:

- Sign-in credentials and OAuth reauthentication after importing an unprotected export (`setup/export.rs`,
  `setup/import.rs`), and rule destination folders resolved after account synchronization.
- Decryption-key identification, valid signatures versus verified key ownership, and multi-recipient encryption
  (`protect.rs`). Key searches can find several keys; publication confirms each address separately (`lookup.rs`).
- Temporary attachment copies removed at startup when older than a day (`clear_private_dirs()`), and
  Internet-origin marking on Windows/macOS (`opening.rs` and platform file-opening code).
- Combined Inbox, Sent and Drafts views, root-level folders, and collapsed unread counts excluding Junk and
  Deleted Items (`tree.rs`).
- Fingerprints and contact addresses checked before confirming verification (`keys.rs` and the dialog code).

Validation: all 68 `pe-i18n`/`pe-html` tests pass. The full-round checks preserve catalog IDs, variables, plural
branches and mnemonic presence; reviewed menu/dialog shortcuts are unique. Help tags, control references, links,
platform branches and keyboard names are preserved. Completed file and English-source hashes match the ledger.
All unmarked changes match the completed inventory (965 catalog entries and 279 help lines). No review marks
remain. `git diff --check` passes. UI behavior and shortcut scopes were checked in source; no GUI was launched.

Final reviewed-content commit: `7c0b1672581c9bd7a33c226f35da16cedca4b528`. `core/locales/REVIEWED` points to this commit.
The review checker passes: 0 pending messages, 0 pending help passages, and 0 unmarked changes.
`build/i18n-review.html` was regenerated and is not committed. Unrelated untracked feedback, language-planning
and responsiveness documents remain untouched.
