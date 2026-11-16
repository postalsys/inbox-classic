# Translation review, round 2, November 2026

Review all newly added language drafts and later edits for fluent, natural wording in the actual app context.
Commit completed batches regularly and preserve an exact resume point.

## Resume here

- Starting checkout: `e99f7e59`; review baseline: `7c0b1672581c9bd7a33c226f35da16cedca4b528`.
- Read `/Users/andris/Downloads/inbox-classic-translation-guide.md`, `core/locales/GLOSSARY.md` (including the
  language's own notes), and `core/crates/pe-html/help/FORMAT.md`.
- Initial scope: 25,353 catalog entries and 992 help pages. Nineteen new languages each have 1,331 entries and
  52 help topics; de/es/et/fr each have 16 new installer/Linux entries and one changed help passage.
- `translation-review-state.json` records exact pending IDs/pages and completed-batch hashes. Compare hashes
  and git history before resuming, so later source or translation changes are not missed.
- Resume with all 52 Portuguese (Portugal) help topics. All 1,331 Portuguese catalog entries are reviewed.
  Italian and Dutch are fully reviewed: each has 1,331 catalog entries and 52 help topics.
  Seventeen new languages remain, with exact pending IDs/topics in the state file.
  No language is considered complete merely because automated checks pass.
- Round 1 is preserved in `translation-review-round1-state.json` and `translation-review-round1-progress.md`.

## Review and checkpoint rules

- Check callers, surrounding controls and actual behavior. Preserve variables, appropriate plurals, literal
  keyboard names, control references, links and platform-specific help branches. Keep terminology consistent.
- Remove marks only for messages/passages actually reviewed. Leave uncertain content marked and explain it.
- Keep `REVIEWED` unchanged until the full round is complete. During partial review, reconcile the review
  checker's unmarked-change reports with the completed inventory.
- `scripts/check-language.mjs` now exists but requires every message/help page to remain marked. Its mark-only
  failures are expected for completed content; require all structural checks to pass. Do not restore marks.
- Run the existing localization/help tests for completed batches and `git diff --check`. Regenerate
  `build/i18n-review.html` without committing it.
- Commit only reviewed files, relevant glossary changes and progress records. Broad Git approval is already
  saved. Preserve the seven unrelated untracked planning/overview documents in `docs/`.
- Do not use the unfiltered `node scripts/i18n-review.mjs` listing: this round produces several MB of output.
  Use `--html`, or capture `--check` and report only the totals/unexpected findings.

## Completed batches

### Existing-language additions

Reviewed all 64 new installer/Linux entries and the four changed language-setting help passages in de/es/et/fr.
Improved 37 values, including literal store descriptions, actual search fields, quoted-message folding, offline
mail availability and Windows user-account installation. No pending content remains in those four languages.
All 72 localization/help tests passed. The installer strings and Linux desktop/metainfo files were regenerated
with `cargo build -p pe-ffi` and inspected; include those generated files in this checkpoint.

### Dutch app catalog

Reviewed all 626 entries in `nl/app.ftl` in two batches (300 and 326). Improved 73 values. Corrected literal
phrasing, incomplete labels, failure messages, rules-versus-sort wording, contact imports, key verification,
backup/restore and account reauthentication after transfer. Fixed the export-dialog mnemonic collision.
All main-menu and new-dialog access keys are unique; all 72 tests and structural catalog checks passed.

The additional sender-address error in `nl/core.ftl` is also reviewed and now names the exact UI field
“Andere afzenderadressen”. All 11 catalog tests passed after that one-string follow-up. Dutch glossary notes
record the field name, rule-processing terminology and digital-signature distinction.

### Dutch core, platform catalogs and first eight help topics

Reviewed the remaining 448 core entries and all 256 platform/help-title entries, improving 111 more values.
Corrected failure and count grammar, queued agent messages, key lookup/publication and decryption details,
settings imports and temporary-attachment cleanup. Native Mac menu conventions are preserved.
All 72 localization/help tests passed; pe-ffi regenerated installer/Linux metadata. The structural checker
reports only intentionally removed marks. Capture its output to a file: piped console output can truncate.

Reviewed eight help topics: add-account, gmail-outlook, main-window, layouts, read-messages, find-messages,
conversations and organize-mail. Improved instructions and updated combined-folder order, unread totals,
search indexing and quoted-message folding from actual app behavior. All 61 help tests passed afterward.

Checkpoint `3eeae77a` saved the first 691 entries and round-1 archive.

### Dutch help completed

Reviewed the remaining 44 topics in six batches. Improved natural instructions throughout and corrected
context in account transfer, key verification, attachment handling, folder creation, agent sending and settings.
All 52 Dutch help topics are now reviewed. Preserved markup, shortcuts, control references and platform branches.
All 72 localization/help tests passed after the final edits. Structural checks pass with only the 1,331
catalog and 52 help marks intentionally removed. Inventory and source hashes reconcile; git diff --check passes.

Checkpoint `d7e3090e` saved Dutch core/platform catalogs and the first eight help topics. Dutch catalog edits
total 185 improved values; the existing-language additions account for the other 37.

### Italian UI catalog

Reviewed all 626 app entries and one shared Windows Save-to-file button, improving 63 catalog values.
Checked main menus, four message-context-menu variants, the address-book context menu and new key/setup
dialogs. Resolved shortcut collisions across shared controls and recorded Italian rule/cryptography terminology.
Improved key ownership, backup/transfer credentials, grammar and provider-name placeholders.
All 72 localization/help tests, structural checks and inventory/hash reconciliation passed.

The expanded context-menu check found six shortcut collisions in Dutch. Eight mnemonic placements were
changed to resolve them across shared menus; visible wording is unchanged. All 11 catalog tests passed afterward.
Dutch now has 193 improved catalog
values. Dutch help checkpoint: `7e7dd500`; Italian UI checkpoint: `9ee040ad`.

### Italian core, platform catalogs and first 19 help topics

Reviewed all 449 core entries and 255 remaining platform/help-title entries, improving 127 values.
Added singular agreement where the code can supply one result, selected item, deleted item or verified part.
Corrected queued agent messages, key protection/publication, imported credentials and count summaries.
Checked platform-specific wording and Cc/Ccn shortcuts. Regenerated and inspected installer and Linux store text.
Italian now has 190 improved catalog values. Dutch shortcut follow-up checkpoint: `becd2162`.

Reviewed the first 19 help topics: account setup, main window, layouts, reading/searching/conversations, mail
organization/deletion, folders, composing/replies/signatures, attachments, message files, drafts/outbox, address book, new mail and unified inboxes. Corrected obsolete
folder navigation and attachment cleanup descriptions, and replaced literal wording with natural instructions.
All 72 localization/help tests passed after catalog changes, followed by the 61 help tests after the first 15
help topics. The next four topics pass structural checks; their Rust tests will run with the next help batch. Structural checks and inventory/hash reconciliation pass; only intentionally cleared marks remain.

### Italian help completed

Reviewed the remaining 33 Italian help topics, completing all 52. Corrected key verification order, signature
ownership claims, private-key recovery, transferred sign-in credentials and rule destination matching. Improved
agent permissions/queued sending, storage and image-download descriptions, troubleshooting and reference text.
Kept all markup, platform branches, control references and literal keyboard tags; documented Italian Cc/Ccn
access keys beside the English combinations in the shortcut table.

All 72 localization/help tests pass after the final edits. Structural checks report only the 1,331 catalog and
52 help marks intentionally removed. Inventory and source/file hashes reconcile, git diff --check passes, and
`build/i18n-review.html` is regenerated. Italian core/platform/everyday-help checkpoint: `3c90b946`.

### Portuguese UI catalog

Reviewed all 626 app entries and improved 69 values. Corrected queued-send tense, rule-processing wording,
field-label agreement, provider fallback grammar, OAuth credentials, settings transfer and key verification.
Checked actual main/context menus and key/setup/rule/contact/recipient dialogs; resolved nine shortcut
placements without changing the platform catalogs. Portuguese glossary notes record terminology choices.
All 11 catalog tests, structural checks and inventory/hash reconciliation pass. Menu and dialog access keys
are unique; git diff --check passes. Italian completion checkpoint: `f3251bd3`.

### Portuguese catalogs completed

Reviewed all 449 core entries and the remaining 256 platform/help-title entries, improving 133 values.
Corrected count agreement, failure guidance, undo labels, queued agent messages, key publication/decryption,
transferred credentials and temporary-attachment cleanup. Improved native platform and installer/store wording.
All 1,331 Portuguese catalog entries are now reviewed, with 202 values improved. Its 52 help topics remain.

The expanded Windows AI Agents dialog check also found three shortcut collisions in previously reviewed Dutch
and Italian controls. Corrected those mnemonic placements; visible wording is unchanged. Dutch now has 194
improved values and Italian 192. Existing German/Spanish/Estonian/French dialog shortcuts pass unchanged.
All 72 tests pass; structural checks, expanded menu/dialog checks and inventory/hash reconciliation pass.
Generated installer/Linux metadata is inspected and git diff --check passes. Portuguese UI checkpoint: `c3509da7`.

Current totals: 4,057 catalog entries and 108 help pages reviewed; 625 catalog values improved. Remaining:
21,296 catalog entries and 884 help pages. `REVIEWED` remains unchanged until the full round is complete.

Context to retain: the new languages were drafted before the last source corrections. Check the round-1 final
consistency findings when reviewing their encryption, transfer, attachment and folder-navigation text.

Additional context for later languages: a TLS-required server response does not prove the password valid;
a malformed message is unreadable by this app, not necessarily every mail app. Attachment opening uses an
external handler after saving a temporary copy. The sign-in-page-file switch writes a URL, not page HTML.
