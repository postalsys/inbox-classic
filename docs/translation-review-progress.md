# Translation review, November 2026

Objective: make the translations read as natural UI and help text in each language, using the actual application
behavior and surrounding controls to establish meaning. Preserve the original scope across sessions.

## Resume here

- Starting checkout: `27616ee9` on `master`; initial review baseline: `94577d0`.
- Read `/Users/andris/Downloads/inbox-classic-translation-guide.md`, `core/locales/GLOSSARY.md`, and
  `core/crates/pe-html/help/FORMAT.md` before continuing.
- `translation-review-state.json` lists the exact pending catalog IDs and help pages. Completed batches record
  their reviewed files and content hashes. Check `git log` and `git status` before using this record: new work may
  have landed since the last batch. Review any subsequent source or translation changes as well.
- Initial inventory: 241 marked messages and 14 marked help passages per language (de, es, et, fr), 964 messages
  and 56 help passages altogether. Each language has ten affected help pages. Other languages named in the guide
  are not present in this checkout. `scripts/check-language.mjs` is also absent here.
- Current next step: German `app.ftl` (94 marked UI entries), then its core/platform catalogs and help.
  Estonian is complete for the starting snapshot. Spanish and French follow. Review existing wording outside
  marked entries when needed for context or terminology consistency.

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

Next: German catalogs (241 marked messages), then its ten help pages. Spanish and French are also untouched.
Estonian catalog and help review is complete for the starting snapshot. Revisit it only for newly arriving changes
or the final cross-language consistency checks below.

Source wording to revisit in the final consistency pass: `ui-setup-passphrase-note` says every account asks for a
password after importing an unprotected file. OAuth accounts instead require signing in again; the reviewed
Estonian text covers both methods. Source evidence: `setup/export.rs` and `setup/import.rs`.

Also revisit English `attachment-decrypted-note` and attachment help: temporary files are removed by
`clear_private_dirs()` at startup if over 24 hours old, not necessarily after exactly a day. The Estonian notice
already reflects this. `pgp-details-opened` identifies the key that successfully decrypted the message; it can
say "Decrypted with your key" more directly than "Encrypted to your key".

Other consistency findings to carry through German, Spanish, French and the English source:

- The encrypted-mail help must not claim an unchecked signature proves the sender's identity. Nor can a
  multi-recipient encrypted message be read only with this user's key: each recipient's private key can open it.
- The multi-account tree is All Inboxes, All Sent, All Drafts, Flagged, then accounts' remaining folders.
  Main-window/organize-mail text must not imply Flagged comes immediately after All Inboxes.
- Collapsed unread totals exclude Junk and Deleted Items (`tree.rs::counted`).
- Internet-origin attachment marking is implemented on Windows and macOS; avoid a blanket Linux claim.
- Check the contact's listed addresses before confirming its fingerprint, not after closing the verification
  dialog. The Estonian steps now include both checks before confirmation.
