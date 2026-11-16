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
- Start with Estonian catalogs, then its related help; repeat for German, Spanish and French. Review existing
  wording outside the marked entries where needed for context or terminology consistency.

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

Next: Estonian `core.ftl` (143 messages), the four marked platform/help labels, then the ten affected help topics.
The other three languages are untouched.

Source wording to revisit in the final consistency pass: `ui-setup-passphrase-note` says every account asks for a
password after importing an unprotected file. OAuth accounts instead require signing in again; the reviewed
Estonian text covers both methods. Source evidence: `setup/export.rs` and `setup/import.rs`.
