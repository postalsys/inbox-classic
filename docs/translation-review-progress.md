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
- Continue in `/Users/andris/Projects/PostalExpress/build/i18n-wave1` on `i18n/review-wave1`.
  This checkout is now authoritative for progress. Merge `d432ebac` includes master checkpoint `5573ee4b`
  and the wave1 branch through `8f2d9848`. Generated installer/store conflicts were resolved by regeneration.
  All five new language structures pass, and all 75 localization/help tests pass after integration.
- Resume with Bulgarian help: all 52 topics remain. All 84 late list-loading labels have been reviewed.
  Bulgarian has 1,334 reviewed catalog entries. Dutch, Italian,
  Portuguese (Portugal), Brazilian Portuguese, Catalan, Norwegian Bokmål, Serbian Latin and Turkish are
  complete: each has 1,334 catalog entries and 52 help topics. Sixteen languages still have pending content,
  with exact IDs/topics in the state file.
  No language is considered complete merely because automated checks pass.
- Additional scope requested during review: Brazilian Portuguese (`pt-BR`), Turkish (`tr`), Norwegian Bokmål
  (`nb`), Catalan (`ca`) and Serbian Latin (`sr-Latn`). Found on local `feat/languages-wave1` at `cfdf55ab`,
  not yet on `master` or `origin/master`. They are included in the isolated review checkout;
  the feature implementation remains on the isolated branch and has not been merged into master.
  This adds 6,655 catalog entries and 260 help topics: scope after that addition was 32,008 entries and 1,252 topics. The later loading labels add 84 entries,
  bringing the current scope to 32,092 entries and 1,252 topics.
  The state records exact inventories and the source commit. Recheck the branch and master for later edits.
- Round 1 is preserved in `translation-review-round1-state.json` and `translation-review-round1-progress.md`.

## Review and checkpoint rules

- Check callers, surrounding controls and actual behavior. Preserve variables, appropriate plurals, literal
  keyboard names, control references, links and platform-specific help branches. Keep terminology consistent.
- Remove marks only for messages/passages actually reviewed. Leave uncertain content marked and explain it.
- After the current queue is complete, check master, the source feature branch and this worktree for new
  languages, new strings and later edits, including already reviewed content. Process those before completion.
- Keep `REVIEWED` unchanged until the full round is complete. During partial review, reconcile the review
  checker's unmarked-change reports with the completed inventory.
- `scripts/check-language.mjs` now exists but requires every message/help page to remain marked. Its mark-only
  failures are expected for completed content; require all structural checks to pass. Do not restore marks.
- User instruction: do not run the test suite; other sessions are running it. Continue structural checks,
  exact inventory/hash reconciliation and `git diff --check`. Record the suite as skipped, without claiming
  that another session tested this review checkout. Regenerate
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

### Portuguese first 21 help topics

Reviewed account setup, main window/layouts, reading/searching/conversations, organization/deletion, folders,
composing/replies/signatures, attachments, message files, drafts/outbox, contacts, new-mail notifications,
combined folders, account management and moving to another computer. Corrected old folder navigation,
attachment cleanup and origin marking, domain-authentication limits, reauthentication after transfer and rule
folder matching. All markup, keyboard tags and platform branches are preserved.
All 72 tests pass. Structural checks and inventory/hash reconciliation pass; git diff --check passes.
Portuguese catalog completion checkpoint: `21f45cd7`.

### Portuguese help completed

Reviewed the remaining 31 help topics, completing all 52. Corrected signature validity versus key ownership,
key-verification order, private-key recovery, logo/domain authentication, image loading, queued agent sending,
connection failures and setup/reference instructions. Checked raw error strings, search fields and native
keyboard shortcuts against the implementation. Preserved markup, control references and all literal keys.
All 72 tests pass; structure, inventory/hash reconciliation, inline control spacing and git diff --check pass.
The review HTML is regenerated. Portuguese first-help and expanded-inventory checkpoint: `a6f1d948`.

### Brazilian Portuguese UI catalog

Reviewed all 626 app entries and nine coupled core/platform controls, improving 88 catalog values. Corrected
queued-send tense, rule processing, required-field grammar, provider fallbacks, OAuth client terminology, key
ownership checks and settings-transfer credentials. Standardized Brazilian Cco controls and their access key.
All actual main menus, four message-context variants and key/setup/agent/rule/contact/recipient dialog scopes
have unique mnemonics. Recorded terminology and coupled field-label changes in the glossary.
All 75 tests, structural checks, inventory/hash reconciliation and git diff --check pass. The root review HTML
now includes the five additional languages. The remaining catalogs and all help topics are still pending.
Portuguese completion checkpoint: `5573ee4b`.

### Brazilian Portuguese catalogs completed

Reviewed the remaining 448 core entries and 248 platform/help-title entries, improving 136 values. Corrected
count agreement, undo descriptions, queued agent logs, credential transfer, key lookup/publication/decryption,
attachment cleanup and native platform wording. All 1,331 catalog entries are reviewed, with 224 values improved.
All 75 localization/help tests pass. Structural checks, inventory/hash reconciliation and git diff --check pass.
Generated installer and Linux store text rebuilt and inspected. UI checkpoint: `8b2ed15c`.
Catalog completion checkpoint: `ce700774`.

### Brazilian Portuguese first 21 help topics

Reviewed account setup, window layouts, reading/searching/conversations, organization/deletion, folders,
writing/replies/signatures, attachments, files, drafts/outbox, contacts, notifications, combined folders,
account management/transfer and provider sign-in. Corrected obsolete folder navigation, Cco terminology,
domain-authentication claims, temporary-attachment lifetime and transferred credentials. Preserved all
markup, control references, keyboard tags and platform branches. All 75 tests, structural checks,
inventory/hash reconciliation, inline spacing and git diff --check pass. The remaining 31 topics are pending.

### Brazilian Portuguese help completed

Reviewed the final 31 help topics, completing all 52. Corrected key ownership/verification, private-key recovery,
domain authentication, image privacy, queued agent sends, connection guidance and command-line behavior.
Checked the rule editor's live match count separately from the rule list's criteria column. Preserved all
markup and literal keyboard tags, with the Brazilian Cco access key explained beside the English shortcuts.
All 75 tests pass, along with structure, inventory/hash reconciliation, inline spacing and git diff --check.
The root review HTML is regenerated. Everyday-help checkpoint: `a879c8ee`.

The feature branch advanced to `cf13ec99`, but its catalog/help translations are unchanged. Catalan is next.

### Catalan UI catalog

Reviewed all 626 app entries and eight coupled core/platform controls, improving 70 values. Corrected rule
processing, queued sends, provider fallback grammar, credential transfer, key ownership and field-label consistency.
Resolved main/context-menu and dialog shortcuts across 32 scopes, including Cc/Cco. Retained vós prose and imperative
shared commands, with terminology recorded in the glossary. All 14 catalog tests, structural checks, inventory/hash
reconciliation and git diff --check pass. Brazilian Portuguese completion checkpoint: `1b5b0c22`.
Catalan's remaining 697 catalog entries and all 52 help topics are pending.

### Catalan catalogs completed

Reviewed the remaining 448 core and 249 platform/help-title entries, improving 148 values. Corrected independent
counts, singular permanent-deletion subsets and verified parts, bounce/undo guidance, queued agent activity,
missing credentials, key lookup/publication/decryption, transfer errors and attachment cleanup. Improved native
status text, installer account scope and Linux store descriptions. Catalan now has 218 improved catalog values.
All 75 tests, structural checks, 32 shortcut scopes, inventory/hash reconciliation and git diff --check pass.
Generated installer/Linux text rebuilt and inspected. UI checkpoint: `e07f6640`. All 52 help topics remain pending.

### Catalan first 21 help topics

Reviewed setup, window layouts, reading/searching/conversations, organization/deletion, folders, writing/replies,
signatures, attachments/files, drafts/outbox, contacts, notifications, combined folders, account management/transfer
and provider sign-in. Corrected old folder navigation, temporary-attachment lifetime, domain authentication,
transferred credentials and rule-folder matching. Fixed platform-specific contractions and improved natural prose.
All 75 tests, structure, inventory/hash reconciliation, inline spacing and git diff --check pass.
Catalog completion checkpoint: `e6e56cff`. The final 31 help topics are pending.

### Catalan help completed

Reviewed the final 31 help topics, completing all 52. Corrected key verification and recovery, domain
authentication, image privacy, queued agent sends, connection failures and command-line/reference guidance.
Preserved markup, platform branches and literal keyboard tags. All 75 tests pass, along with structure,
inventory/hash reconciliation, inline spacing and git diff --check. The review HTML is regenerated.
Everyday-help checkpoint: `37a547aa`. Norwegian Bokmål is next.

### Norwegian Bokmål UI catalog

Reviewed all 626 shared UI entries and three coupled Windows controls, improving 54 values. Corrected rule
processing, key ownership checks, credential transfer and domain-authentication wording. Resolved shortcut
collisions in 32 actual menu and dialog scopes. All 14 catalog tests, structure, inventory/hash reconciliation
and git diff --check pass. Catalan completion checkpoint: `21f37354`. The remaining catalogs and help are pending.

### Norwegian Bokmål catalogs and first 21 help topics completed

Reviewed the remaining 449 core and 253 platform/help-title entries, improving 113 values. All 1,331 catalog
entries are reviewed, with 167 improved values. Corrected counts, queued agent logs, delivery errors, key
lookup/publication/decryption, credential transfer, attachment cleanup and native platform guidance.
Reviewed 21 everyday help topics, including current folder navigation, search indexing, domain authentication,
attachment handling and transfer instructions. All 75 tests, structure, inventory/hash reconciliation, inline
spacing, 32 shortcut scopes and git diff --check pass. Generated installer/Linux text rebuilt and inspected;
the review HTML is regenerated. UI checkpoint: `257675e2`. The final 31 help topics remain pending.

### Norwegian Bokmål help completed

Reviewed the final 31 help topics, completing all 52. Corrected signature validity versus ownership,
private-key recovery, domain/logo checks, image privacy, queued agent sending, credential troubleshooting
and command-line/reference guidance. Quoted localized errors match the catalogs; original keyboard tags
are preserved with Norwegian Kopi/Blindkopi access keys explained. All 75 tests, structure, inventory/hash
reconciliation, inline spacing and git diff --check pass. The review HTML is regenerated.
Catalog/everyday-help checkpoint: `d0370fc9`. Serbian Latin is next; the source branch has no new translation changes.

### Serbian Latin UI catalog

Reviewed all 626 shared UI entries and one coupled core error, improving 81 values. Reworked literal Serbian
phrasing, provider and key terminology, junk/ham actions, recipient/contact plural agreement, rule processing,
credential transfer and ownership verification. Matched the sender-address error to its field label.
All 14 catalog tests, structure, 32 actual shortcut scopes, inventory/hash reconciliation and git diff --check pass.
Norwegian Bokmål completion checkpoint: `9d63e925`. Core, platform catalogs and help remain pending.

### Serbian Latin catalogs completed

Reviewed the remaining 448 core and 256 platform/help-title entries, improving 138 values. Serbian Latin now
has all 1,331 catalog entries reviewed and 219 improved values. Corrected counted-phrase case agreement,
recurring intervals, queued agent logs, key lookup/publication/decryption, transfer details and attachment
cleanup. Improved platform guidance, installer user scope and Linux store text. All 75 tests, structure,
inventory/hash reconciliation, 32 shortcut scopes and git diff --check pass. Generated installer/Linux metadata
rebuilt and inspected; the review HTML is regenerated. UI checkpoint: `1af7454e`. All 52 help topics are pending.

### Serbian Latin first 21 help topics

Reviewed everyday help from setup and navigation through writing, attachments, contacts, account transfer
and provider sign-in. Corrected current folder navigation and unread counts, domain authentication,
temporary-attachment lifetime, transferred credentials and rule-folder matching. Improved natural Serbian
instructions and preserved markup, keyboard tags and platform branches. All 75 tests, structure,
inventory/hash reconciliation, inline spacing and git diff --check pass. The review HTML is regenerated.
Catalog completion checkpoint: `bd8902d4`. The remaining 31 help topics are pending.

### Serbian Latin help completed

Reviewed the final 31 topics, completing all 52 help pages. Corrected key verification and recovery,
domain/logo checks, image privacy, queued agent sends, credential troubleshooting and reference guidance.
Localized error quotes match the catalogs, and markup, shortcuts and platform branches are preserved.
All 75 tests, structure, inventory/hash reconciliation, inline spacing and git diff --check pass; the review
HTML is regenerated. Everyday-help checkpoint: `a4bdb41a`. Turkish is next. The source branch remains
`cf13ec99`, with no new catalog/help translations since the integrated source checkpoint.

### Turkish UI catalog

Reviewed all 626 shared UI entries and two coupled core/Windows entries, improving 75 values. Reworked
sign-in, rule processing, queued sending, fingerprint verification, credential transfer and image privacy.
The sender-address error now quotes the exact field label. All 14 catalog tests, structural checks,
32 actual shortcut scopes, inventory/hash reconciliation and git diff --check pass. Two native letters
avoid artificially lengthened commands; dotted/dotless i is excluded. Glossary decisions are recorded.
Serbian Latin completion checkpoint: `ad3fe778`. Remaining 703 catalog entries and 52 help topics are pending.

### Turkish catalogs completed

Reviewed the remaining 448 core and 255 platform/help-title entries, improving 134 more values. Turkish now
has all 1,331 entries reviewed and 209 improved values. Corrected delivery failures, queued agent logs,
key discovery/recovery/decryption, settings-file terminology and temporary attachments. Improved native
platform guidance, installer user scope and Linux store text. All 75 tests, structure, 32 shortcut scopes,
inventory/hash reconciliation and git diff --check pass. Generated installer/Linux metadata rebuilt and
inspected; the review HTML is regenerated. UI checkpoint: `0fc92730`. All 52 help topics remain pending.

### Turkish first 21 help topics

Reviewed setup, navigation, reading/search, conversations, organization, writing/replies, signatures,
attachments/files, drafts/outbox, contacts, notifications and account management/transfer. Replaced literal
phrasing and corrected current combined-folder navigation, unread counts, local indexing, attachment cleanup,
domain authentication, transferred credentials and rule-folder matching. All 75 tests, structure,
inventory/hash reconciliation, inline spacing and git diff --check pass; the review HTML is regenerated.
Catalog completion checkpoint: `2525089a`. The final 31 help topics remain pending.

### Turkish help completed

Reviewed the final 31 topics, completing all 52 help pages. Improved key verification and recovery,
domain and logo checks, image privacy, queued agent sending, connection troubleshooting and reference text.
Localized error quotes match the catalogs; literal keyboard tags are preserved with Bilgi/Gizli shortcuts
explained. All 75 tests, structure, inventory/hash reconciliation, inline spacing and git diff --check pass.
The review HTML is regenerated. Everyday-help checkpoint: `4eda4a34`. Bulgarian is next. Master and the
feature branch have no new catalog/help translations since the last source audit.

### Bulgarian UI catalog

Reviewed all 626 shared UI entries and three coupled core/Windows entries, improving 68 values. Corrected
literal phrasing, send statuses, rules, provider fallback grammar, sender aliases, key ownership verification
and credential transfer. Resolved seven shortcut placements across 32 actual menu and dialog scopes.
All 14 catalog tests, structure, inventory/hash reconciliation and git diff --check pass. Turkish completion
checkpoint: `36dc6ce6`. Remaining catalogs and all 52 Bulgarian help topics are pending.

### Bulgarian catalogs completed

Reviewed the remaining 448 core and 254 platform/help-title entries, improving 151 values. All 1,331 Bulgarian
catalog entries are reviewed, with 219 values improved. Corrected delivery/count wording, queued agent logs,
key lookup and recovery, credential transfer, temporary-attachment cleanup, native controls and installer/store
text. All 75 tests, structural checks, 32 shortcut scopes, inventory/hash reconciliation and git diff --check
pass. Generated installer/Linux metadata rebuilt and inspected; the review HTML is regenerated.
UI checkpoint: `5594397a`. All 52 Bulgarian help topics remain pending. Some everyday topics have been read,
but no help passages are recorded as reviewed or edited yet.

The user requested a translation-editor skill during this batch. Installed and validated it at
`~/.codex/skills/translation-editor/SKILL.md`, based on `~/Downloads/translation-editor-skill.md`.
It retains the final late-arrival audit before round completion and resumes from these records.

### Late source integration: list loading

Fetched upstream and incorporated `origin/master` at `fd7feeaf`, then imported the 15 new platform entries
from local `feat/languages-wave1` at `e932e78f`. This adds 84 entries across all 28 translated languages,
three per language, for a total scope of 32,092 catalog entries. Existing catalog values/comments/marks are
verified unchanged. Resolved the store initialization merge by retaining Unicode fold registration and
upstream list-view state. No test suite was run, as requested. The current guide was reread after its hash
changed. Review the new list-loading labels next; the baseline remains unchanged.

### Late list-loading labels reviewed

Reviewed all 84 platform labels in their actual transient message-list overlays. Existing wording is suitable;
three Catalan values now use the same apostrophe as the rest of the catalog. Structural checks across all 28
languages pass after accounting for reviewed marks and seven parser false positives in older multiline
messages. Their complete variable sets were independently checked against English; exact IDs are in the state.
Inventory/source/file hashes reconcile and git diff --check passes. The test suite was intentionally not run,
as requested. Integration checkpoint: `f8648cd2`. Bulgarian help is next.

Maintainer note: `scripts/check-language.mjs` stops a message at an unindented closing brace and misses variables
on that line. The runtime/catalog test's reader handles these continuation lines. This checker issue is recorded,
not repaired as part of translation editing. None of the seven findings indicates a missing placeholder.

Current totals: 12,127 catalog entries and 420 help pages reviewed; 1,884 catalog values improved. Remaining:
19,965 catalog entries and 832 help pages (including the five additional languages). `REVIEWED` remains unchanged until the full round is complete.

Context to retain: the new languages were drafted before the last source corrections. Check the round-1 final
consistency findings when reviewing their encryption, transfer, attachment and folder-navigation text.

Additional context for later languages: a TLS-required server response does not prove the password valid;
a malformed message is unreadable by this app, not necessarily every mail app. Attachment opening uses an
external handler after saving a temporary copy. The sign-in-page-file switch writes a URL, not page HTML.
