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
- Finnish is complete: 1,340 catalog entries and all 52 help topics reviewed, with 174 catalog value
  improvements. The 168 new rollback messages are reviewed in fi/de/es/et/fr (30 entries); 138 remain
  across the other 23 languages. Continue those, then Croatian (hr) and the remaining ten initial-review
  languages. The notification-context followup is complete across all 17 previously reviewed languages:
  all 32 queued topics corrected, with Finnish handled earlier. Apply the glossary context note to the
  remaining initial reviews. Followup topics are separate from initial-scope totals.
  The extended mnemonic followup is complete: 44 actual menu/dialog scopes pass across all 17 languages
  with reviewed catalogs. Use the expanded scopes for remaining languages; exact definitions are in state.
  Upstream master `76f67e82` is integrated and its already-inventoried wave1 content reconciled.
  Greek’s original scope is complete: 1,334 catalog entries, 211 values improved, all 52 help topics. The logo-cache and
  attachment-reminder context followups are complete. Eleven languages still need their initial reviews; 23 have the new rollback drafts pending. All 84 late list-loading labels are reviewed.
  Bulgarian, Czech, Danish, Dutch, Italian, Portuguese (Portugal), Brazilian Portuguese, Catalan,
  Norwegian Bokmål, Serbian Latin and Turkish have completed their initial reviews.
  The persistent-logo-cache followup is now complete: 42 help topics checked (37 changed, five retained)
  and 14 already-reviewed settings descriptions corrected. These re-reviews are counted separately.
- Additional scope requested during review: Brazilian Portuguese (`pt-BR`), Turkish (`tr`), Norwegian Bokmål
  (`nb`), Catalan (`ca`) and Serbian Latin (`sr-Latn`). Found on local `feat/languages-wave1` at `cfdf55ab`,
  not yet on `master` or `origin/master`. They are included in the isolated review checkout;
  the feature implementation was initially isolated and has now reached origin/master at `76f67e82`.
  The translation review edits remain on the isolated review branch.
  This adds 6,655 catalog entries and 260 help topics: scope after that addition was 32,008 entries and 1,252 topics. The later loading labels add 84 entries,
  bringing that scope to 32,092 entries and 1,252 topics. The 168 later rollback messages increase
  the current scope to 32,260 entries and 1,252 topics.
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

### Bulgarian first 21 help topics

Reviewed everyday help: setup, navigation/layouts, reading/search, conversations, organizing/deleting mail,
folders, writing/replies/signatures, attachments/files, drafts/outbox, contacts, notifications, combined folders
and account management/transfer. Improved natural instructions and corrected current folder navigation, unread
counts, local indexing, domain authentication, temporary-attachment lifetime, credential transfer and rule-folder
matching. Structure, markup/keyboard preservation, inline spacing, inventory/hash reconciliation and git diff
--check pass. Review HTML regenerated. No test suite was run per user instruction. Catalog checkpoint:
`a5c0a9e9`; late-loading checkpoint: `4a038b57`. The final 31 Bulgarian help topics remain pending.

### Bulgarian help completed

Reviewed the remaining 31 topics: security/encryption, privacy, rules, agents, troubleshooting and reference.
Corrected key ownership versus signature validity, verification order, recovery, logo limits, queued sending,
credential guidance and the sign-in URL file. Preserved all markup and literal keys; explained Bulgarian access
keys beside the literal shortcut table. All 52 Bulgarian topics are now reviewed. Structural checks, exact
inventory/hash reconciliation and git diff --check pass; review HTML regenerated. Test suite not run per user
instruction. First-help checkpoint: `fdd65857`.

Fresh upstream check: master remains `fd7feeaf`; local/remote wave1 advanced to `8df686a4`, whose change since
`e932e78f` has no catalog/help edits. The final late-arrival audit remains required after the current queue.

### Czech shared UI catalog

Reviewed 626 app entries and four shared Windows controls, improving 66 values. Corrected rule processing,
queued messages, provider/name grammar, digital signatures, multiple key addresses and sign-in credentials in
settings transfer. Resolved shortcut collisions across 32 actual menus/dialogs, including context-menu variants.
Recorded Czech terminology and Kopie / Skrytá kopie shortcuts. Structural checks, inventory/source/file hashes
and git diff --check pass. Review HTML regenerated. Test suite not run per user instruction.
Bulgarian completion checkpoint: `7ff487c3`.

### Czech catalogs completed

Reviewed the remaining 701 entries, improving 130 values. Corrected delivery errors, queued agent log messages,
key publication/decryption, sign-in credentials, file counts and startup cleanup of temporary attachments.
Unified Skrytá kopie across platforms and improved the installer and Linux app description. All 1,334 Czech
catalog entries are reviewed; all 52 help topics remain. Shared UI checkpoint: `4f30e962`.

Structural checks, 32 actual menu/dialog shortcut scopes, exact inventory/source/file hashes and git diff
--check pass. Installer/store text regenerated and inspected with an offline pe-ffi build using the separate
`/Users/andris/Projects/PostalExpress/build/cargo-translation-review` target directory. Review HTML regenerated.
No tests were run, per user instruction.

### Czech first 21 help topics

Reviewed everyday help from account setup through account transfer. Corrected combined-folder navigation,
unread counts, search indexing, conversation actions, signatures, attachment cleanup, domain-authentication
limits and sign-in credentials. Improved Czech instructions throughout while preserving all markup, platform
branches and literal keyboard tags. Structural checks, inline spacing, exact inventory/source/file hashes and
git diff --check pass. Review HTML regenerated. Test suite not run per user instruction.
Catalog completion checkpoint: `c13d96a7`.

### Czech help completed

Reviewed the remaining 31 topics, including security, privacy, rules, agents, troubleshooting and reference.
Corrected key ownership/verification, queued sending, sign-in credentials, URL output and localized Cc/Bcc keys.
The search parser treats to:, cc: and bcc: as aliases across all recipient fields; the help explains this.
All 52 Czech topics are reviewed. Structural checks, preserved markup/keyboard text, inline joins and exact
inventory/file/source hashes pass. Review HTML regenerated; no test suite was run per user instruction.
First-help checkpoint: `bdf0dc0b`.

Fresh upstream check: origin/master advanced to `65988ba4` with release-review tooling changes only; no catalog
or help content changed. Local/remote wave1 remain `8df686a4`. Merged updated tooling as `4cb0158b`; no conflicts. Updated --since and full inventory/hash checks reconcile.

### Danish shared UI catalog

Reviewed 626 app entries and two Windows controls shared with context menus, improving 58 values. Corrected
rule processing, account-transfer login details, cryptographic terminology, recipient/key grammar, sender-image
context and natural Danish instructions. Checked actual message-sent events, rule counts and key dialogs.
Resolved access-key conflicts across 32 menu/dialog scopes, including all four message-context variants.
Structural checks, exact inventory/file/source hashes and git diff --check pass; review HTML regenerated.
No test suite was run per user instruction. Czech completion checkpoint: `a1d1de33`.

A source-context followup is recorded with 42 exact help paths across the 14 already-reviewed languages:
brand-logos, connections and pictures-tracking. LogoSource now reuses a persistent cache (30-day lifetime,
one-day failure backoff), while English help describes once-per-run downloads. Check those translated timing
claims and retain the explanation of what a server sees when a download actually occurs. This followup must
be completed in addition to the pending language queue; English/app code remain outside this task.

### Danish catalogs completed

Reviewed the remaining 703 core/platform/help-title entries and improved 133 values. Corrected independent
unread counts, singular file failures, delivery guidance, queued agent messages, key publication/decryption,
transferred credentials and temporary-attachment cleanup. Improved installer and Linux store descriptions.
All Danish catalog entries are now reviewed; 52 help topics remain. Shared UI checkpoint: `d8506557`.

Structural checks, complete placeholder sets, 32 menu/dialog shortcut scopes and exact inventory/file/source
hashes pass. A bookkeeping path-variable error was caught by reconciliation and the untouched Turkish help
file restored byte-for-byte before this commit; its source hash now matches. Four installer strings and five
Linux store strings regenerated and inspected with an offline pe-ffi build in the isolated target directory.
Review HTML regenerated and git diff --check passes. No test suite was run per user instruction.

### Danish first 21 help topics

Reviewed everyday help from account setup through account transfer. Improved natural instructions and corrected
combined-folder navigation, unread counts, search indexing, signatures, attachment cleanup and domain-authentication
claims. Clarified queued sending, account removal/transfer credentials and rule-folder matching. Preserved all
markup, platform branches and keyboard literals. Structural checks, inline joins, exact inventory/file/source
hashes and git diff --check pass. Review HTML regenerated. No test suite was run per user instruction.
Catalog completion checkpoint: `e1680ea3`.

### Danish help completed

Reviewed the final 31 topics, including security/privacy, agent permissions, troubleshooting and reference.
Corrected key ownership versus signature validity, persistent logo caching, domain authentication, attachment
opening, queued agent sending and sign-in credentials. Error quotations match the catalogs; search aliases
correctly describe all recipient fields. Preserved tags, attributes, platform branches and literal shortcuts.
All 52 Danish help topics are reviewed. Structural checks, inline joins, exact inventory/file/source hashes
and git diff --check pass. Review HTML regenerated. No test suite was run per user instruction.
First-help checkpoint: `a0d3cb72`.

### Persistent logo-cache context followup completed

Checked all 42 recorded help paths in 14 previously reviewed languages. Improved 37 files; five generic
pictures-tracking passages needed no change. Also reviewed and corrected ui-list-pictures-note in those
14 languages. Logos are saved and reused across restarts, with a 30-day cache and one-day failure backoff in
the implementation; help describes reuse without promising a download once per run or absolute privacy.
An actual download can reveal the request time and IP address. Clarified domain authentication and Address
Book pictures where the older wording was misleading. English/help source inconsistencies remain a maintainer
note; no English or application code was changed.

These are context re-reviews, not newly completed initial-scope entries. State batches record them separately
as followup_reviewed_ids/help, with new translation/source hashes. Reconciliation includes the four old
catalog IDs and changed help passages in de/es/et/fr without inflating the initial-scope totals below.
Structural checks in all 14 languages pass after accounting for marks and the same seven independently
verified parser false positives. Tags, attributes, keyboard text and inline joins are preserved. Exact
inventories/hashes and git diff --check pass; review HTML regenerated. No test suite was run.

Fresh upstream check after Danish completion: origin/master remains 65988ba4 and local/remote wave1 remain
8df686a4; no new catalog/help changes. Captured --since audit found no newly pending entries. The final audit
remains required after the current queue. Danish completion checkpoint: `4d43ead4`.

### Greek shared UI catalog

Reviewed 626 shared UI entries and the Windows Delete button used in message context menus, improving
64 values. Corrected rule processing, compose actions, placeholder/fallback grammar, key ownership and
verification order, digital signatures, transferred credentials and persistent logo caching. Recorded Greek
terminology and Cc/Bcc shortcuts. Resolved access-key collisions across 32 actual menu/dialog scopes.
Structural checks, complete placeholder sets, exact inventories/hashes and git diff --check pass. No Greek
tour screenshots are available. Review HTML regenerated; no test suite was run per user instruction.
Logo-cache followup checkpoint: `01e480de`.

### Greek core catalog

Reviewed all 449 core entries and improved 110 values. Fixed independent unread/search counts and singular
permanent deletions, Greek case around counted messages, delivery explanations and queued agent sends.
Corrected key ownership, publication confirmation for every address, decryption details, credentials and
settings-file terminology. Temporary-attachment guidance now describes cleanup at startup, not after a day
regardless of app state. Relevant caller conditions were checked directly. Structural checks, full placeholder
sets, exact inventory/file/source hashes and git diff --check pass; review HTML regenerated. No test suite
was run per user instruction. Shared UI checkpoint: `3e78559d`.

### Greek catalogs completed

Reviewed the remaining 255 Windows/macOS/GTK/installer/store/help-navigation entries and improved 37 values.
All 1,334 Greek catalog entries are now reviewed; all 52 help topics remain. Corrected failed-file counts,
placeholder grammar, agent removal, Windows account scope and natural Linux store descriptions. Preserved
provider-branded sign-in labels and localized Cc/Bcc shortcuts. Core checkpoint: `a092514b`.

All catalog structures, full placeholder sets, 32 shortcut scopes and exact inventory/file/source hashes pass.
An offline pe-ffi build in the isolated Cargo target regenerated three installer and five store values, which
were inspected. Review HTML regenerated and git diff --check passes. No test suite was run per user instruction.

### Greek first 21 help topics

Reviewed everyday help from account setup through account transfer. Improved natural Greek instructions,
matched control names and corrected combined-folder navigation, unread totals, indexing, bulk actions,
signatures, attachments, queued sending and transferred credentials. Clarified temporary attachment cleanup
at startup and its platform-specific origin marking. Sender-picture authentication confirms the domain,
not the person or message content. Preserved tags, attributes, keyboard literals and platform branches.
Structural checks, inline joins, exact inventory/file/source hashes and git diff --check pass; review HTML
regenerated. No test suite was run per user instruction. Catalog completion checkpoint: `4274d4d3`.

New source-context finding: `attachment_words.rs` recognizes attachment reminders only in English, German,
Estonian, Spanish and French. The Greek help now uses a recognized English example and names this limitation.
Eleven previously reviewed write-message topics need the same check, recorded as a separate context followup.
Check this limitation while reviewing the twelve remaining languages. English and app code are unchanged.

### Attachment-reminder context followup completed

Corrected all 11 previously reviewed write-message paragraphs in bg/ca/cs/da/it/nb/nl/pt/pt-BR/sr-Latn/tr.
Each now uses the recognized English example “attached” and states that the reminder detects selected words
only in English, German, Estonian, Spanish and French. The code currently has no keywords for the other
languages. Greek received this correction in its initial help batch; check the remaining languages likewise.
These are separate re-reviews, not additional initial-scope completions. All 11 structures pass; markup,
attributes, keyboard literals and inline joins are preserved. Exact inventories/file/source hashes reconcile,
git diff --check passes, and the review HTML is regenerated. No test suite was run. Greek first-help checkpoint:
`a41119fe`.

### Greek security and privacy help

Reviewed 13 more topics: encrypted/signed mail, keys and verification, account security, logos, remote images,
connections, storage, download-ahead, links/scripts, sign-in codes, unsubscribe and invitations. Corrected
signature validity versus ownership, verifying every address before accepting a key, private-key recovery,
persistent logo reuse, request privacy and domain-authentication limits. Clarified attachment opening through
external applications, per-account storage limits, OAuth credentials and natural Greek instructions.
All markup, attributes, literal keys and platform branches are preserved. Structural checks, inline joins,
exact inventory/file/source hashes and git diff --check pass; report regenerated. No test suite was run.
Greek help is now 34/52. Attachment-reminder followup checkpoint: `d982d60b`.

### Greek help completed

Reviewed the final 18 topics: rules, agents, troubleshooting and reference. Corrected queued-send behavior,
agent permission scope, rule processing, TLS-required responses, certificate-error causes, app-specific message
rendering failures and transferred sign-in credentials. Search to/cc/bcc aliases correctly cover every recipient
field. Greek name examples use Greek text, and localized Alt+Κ/Alt+Ι are explained beside the preserved literal
English shortcuts. The CLI sign-in-page-file description correctly identifies a URL. All 52 Greek help topics
are reviewed. Structural checks, preserved markup/keys, inline joins and exact inventories/hashes pass;
git diff --check passes and report regenerated. No test suite was run. Security-help checkpoint: `fd00285e`.

Fresh upstream discovery: origin/master is now `76f67e82`, merging the wave1 feature branch already included
in this review round. Local master remains `5573ee4b`; local/remote wave1 remain `8df686a4`. Comparing that
feature tip with new origin/master shows no localization/help/command changes. Integrate mainline ancestry
and reconcile after this Greek checkpoint before continuing Finnish. The full late-arrival audit is still
required once all twelve pending languages are complete.

### Upstream integration after Greek completion

Integrated origin/master `76f67e82`, which merged the five wave1 languages already reviewed here. Duplicate
history caused conflicts in their draft translations and language infrastructure. Kept reviewed catalog/help,
glossary and generated translations, and adopted the inspected upstream source versions. One automatic merge
duplicated fold::register; resolved the file to the upstream version. All 15 integrated source paths now match
origin/master exactly. The isolated offline pe-ffi build passes, with no tests run. Existing generated translations
are unchanged; the new generated languages.tsv matches upstream and is recorded in the state.

All 28 translated languages have the required catalog IDs, variable sets and help topics. Pending marks match
exactly 15,972 catalog entries and 624 help topics; completed file/English-source hashes reconcile. The captured
--since starting-commit audit reports zero newly pending messages/passages. The 24,538 intentionally unmarked
changes reconcile to 16,124 catalog messages and 8,414 help lines (including separate context followups).
Both working-tree and staged whitespace checks pass. Greek completion checkpoint: `fd1002f6`. Continue Finnish.

### Finnish UI catalog

Reviewed all 626 shared UI entries and one coupled Windows button, improving 59 values. Corrected unnatural
status/failure wording, account/provider placeholders, rule processing, contact counts, key ownership and
address verification, saved sign-in credentials and protected transfers. Sender-image text now distinguishes
verified domains from people and explains persistent logo reuse. Recorded Finnish terminology in the glossary.

Thirty-two actual menu/context/dialog scopes have unique access keys, including native ä/ö. Source inspection
confirmed that Open appears only for a single draft and Not Junk only for Junk messages, so these two controls
never coexist; the generic mnemonic helper had incorrectly combined them. Compose Kopio/Piilokopio retain
Alt+K/Alt+P, with the recipient picker's separate scope checked. Existing contact-import screenshot inspected;
no Finnish tour screenshots are available. IDs, full variable sets, plural branches and mnemonic counts are
preserved. Structural and inventory/hash checks pass, report regenerated and git diff --check passes.
The test suite was not run. Upstream integration checkpoint: `03d0b346`.

### Finnish core catalog

Reviewed all 449 core entries, improving 75 values. Corrected delivery guidance, unnatural status/count
phrasing, sign-in credentials and settings-import results. Agent send logs now describe adding a message to
the send queue. Key details correctly describe decryption, missing private keys and restoring a private-key
backup; publication instructions require confirming every listed address. Temporary plaintext attachment
copies are removed on startup once older than a day. The Organize permission stays concise for its single-line
Windows checkbox. Existing plural structures and all placeholders are preserved.

Structural checks report only deliberately removed review marks. Exact inventories and completed-file/source
hashes reconcile, review HTML regenerated and git diff --check passes. No test suite was run.
Finnish UI checkpoint: `1da11a3f`. Its 255 remaining platform/help-title entries and all 52 help topics are next.

### Finnish catalogs completed

Reviewed the 255 remaining platform/help-title entries and rechecked two shared UI controls, improving 39
values. Corrected Windows-user installation wording, background-mail notices, file-save failures, account
fallbacks, queued timestamps and Linux store descriptions. Retained native Mac terms and branded sign-in labels.
The expanded audit covers 43 actual menu/dialog scopes and fixed collisions in Settings, account/folder menus
and the copy dialog. Its additional scopes will also be checked across previously reviewed languages.

All 1,334 Finnish catalog entries are reviewed, with 173 values improved. Its 52 help topics remain.
Static structure, exact inventories/hashes and git diff --check pass; review HTML regenerated. Offline pe-ffi
build in the dedicated target passed and regenerated installer/Linux metadata, inspected and included.
No test suite was run. Finnish core checkpoint: `4c1a1fcb`.

### Expanded native menu and dialog shortcuts

Audited all 17 languages with reviewed catalogs across 44 actual scopes. Added Settings/accounts, account/folder
context menus, the folder picker and runtime Flag colour shortcuts to the original 32-scope check. Fixed 74
catalog mnemonic positions in 16 languages without changing visible wording; Bulgarian passed unchanged.
The colour menu assigns the first unused letter at runtime, which Clear Flag must avoid. French Cci now uses
Alt+I on Windows and Linux; its keyboard-shortcuts topic explains localized Alt+C/Alt+I beside preserved literal
English key tags. This followup does not add entries or topics to the initial review inventory.

All 44 scopes and complete catalog ID/variable sets pass. Static checks account only for removed review marks
and the seven recorded es/fr multiline-parser false positives. Exact completed inventories and source/file
hashes reconcile; help markup and literal keys are preserved. Review HTML regenerated, git diff --check passes.
No test suite was run. Finnish catalog checkpoint: `ac13722a`. Continue its 52 help topics.

### Finnish first eight help topics

Reviewed account setup, Google/Microsoft sign-in, main window, layouts, reading, search, conversations and
message organization. Improved natural instructions and corrected combined Sent/Drafts navigation, collapsed
unread counts excluding Junk/Deleted, search indexing versus reading and display-date behavior. Clarified
folded quoted messages and conditional app-password support. All markup, attributes, control references,
platform branches and literal keyboard tags are preserved.

Static structural checks, inline joins, exact inventories and source/file hashes pass. Review HTML regenerated;
git diff --check passes. No test suite was run. Forty-four Finnish help topics remain.
Expanded mnemonic followup checkpoint: `b3b4ac1c`.

### Finnish everyday and account help

Reviewed 13 more topics: deleting/undo, folders, writing/replies, signatures, attachments, message files,
drafts/outbox, address book, new mail, combined folders, accounts and transfer. Improved literal wording and
corrected attachment-reminder language support, temporary plaintext attachment storage, queued-send retries
and cancellation, sender-domain authentication and protected transfers including saved sign-in credentials.
Combined-folder navigation and signatures now describe the actual controls and behavior clearly.

Re-read the completed conversations topic and clarified watched-conversation notifications. All three platform
handlers honor notification settings and suppress notices while the main window is in front. The core announces
watched messages in Inbox and user folders, not every special folder. English still says "always"; no English
or implementation files changed. State queues a precise audit of conversations/new-mail in the 16 other
languages with reviewed help. Apply this context during the initial review of remaining languages too.

Static checks have no structural findings beyond intentionally removed marks. All 14 edited help files preserve
markup, attributes, controls, platform branches and literal keys. Exact pending inventories and completed/source
hashes reconcile (17,503 catalog messages and 8,730 changed help lines). Report regenerated; git diff --check
passes. No test suite was run. Finnish now has 21 of 52 help topics reviewed; 31 remain.
Previous Finnish help checkpoint: `24d0f269`.

### Finnish security and privacy help

Reviewed 13 topics covering pictures/tracking, links/scripts, logos, connections, account security, sign-in
codes/apps, storage, background downloads, encrypted/signed mail, keys, verification and encryption errors.
Corrected persistent logo reuse and download privacy, domain authentication versus personal identity, external
attachment opening, saved browser credentials and local download limits. Digital signatures now describe
content integrity separately from verified key ownership. The verification steps check every address before
confirmation closes the dialog. Locked keys require a private-key backup; a TLS-required response does not
prove that a password is correct. Recorded consistent Finnish logo and OAuth terminology in the glossary.

Static checks have no structural findings beyond intentionally removed marks. Markup, attributes, controls,
platform branches and literal keys are preserved. Pending inventories and completed/source hashes reconcile
(17,503 catalog messages and 8,868 changed help lines). Report regenerated; git diff --check passes.
No test suite was run. Finnish now has 34 of 52 help topics reviewed; 18 remain.
Everyday/account help checkpoint: `037aefcd`.

### Finnish help completed

Reviewed the final 18 help topics covering rules, agents, troubleshooting, installation and reference material.
Improved natural instructions and clarified rule processing, agent permission scope, queued-send approval and
cancellation, TLS failures, conditional app-password support and command-line behavior. Search examples now
match date boundaries and recipient-field behavior. Unsubscribe instructions distinguish direct requests,
prepared messages and browser actions. Finnish compose shortcuts Alt+K/Alt+P are explained beside unchanged
literal key tags. All 1,334 catalog entries and all 52 Finnish help topics are now reviewed.

Static checks have no structural findings beyond deliberately removed marks. Markup, attributes, controls,
platform branches and literal keys are preserved. All 28 language inventories and pending marks match state;
completed/source hashes reconcile (17,503 catalog messages and 9,114 changed help lines). Report regenerated;
git diff --check passes. No test suite was run. Security/privacy checkpoint: `d45745a0`.

### Late server-action failure messages discovered

After Finnish checkpoint `4369af4a`, fetched upstream master `46b938a7` and found six new `undone-*` drafts
in each of the 28 languages, 168 messages in total. No existing catalog values, help topics or language
inventories changed. Integrated upstream into the isolated review branch, preserving all previous English
and translated corrections. The 58 imported implementation/generated paths match upstream exactly. Each
language records a source-integration checkpoint; the six new entries remain marked and explicitly pending.

All catalog IDs, variable sets, help inventories, pending marks and completed/source hashes reconcile.
Static checks report only known removed-mark diagnostics and seven recorded es/fr parser false positives.
The dedicated offline pe-ffi build passed; generated output is unchanged from imported upstream files.
No test suite was run. Review the 168 new messages next, then the notification-context followup.

### First late rollback reviews and notification corrections

Reviewed all 30 new failure messages in Finnish, German, Spanish, Estonian and French against the merged
app implementation. Checked counted-message phrases, singular/plural agreement and restored local state after
a failed server action. Retained good drafts; improved two Spanish status descriptions and one French flag
sentence. Finnish is complete again, now at 1,340 catalog entries and 52 help topics.

Corrected eight conversations/new-mail help topics in de/es/et/fr: watching includes messages in user folders,
but notification settings and foreground-window suppression still apply. Rechecked all three handlers in the
merged source. Twenty-four followup topics remain in 12 languages; these do not increase initial-scope totals.

Static checks have no unexpected structural findings; the seven known es/fr parser false positives are
accounted for. Catalog variables/plurals and help tags/attributes/literal keys are preserved. All inventories
and completed/source hashes reconcile (17,533 messages and 9,122 changed help lines). Report regenerated;
git diff --check passes. No test suite was run. Upstream integration checkpoint: `b4dbd1e3`.

### Watched-conversation notification followup completed

Corrected the remaining 24 help topics in nl/it/pt/pt-BR/ca/nb/sr-Latn/tr/bg/cs/da/el, preserving each
language's register and terminology. All 32 queued conversations/new-mail topics are now corrected, with
Finnish handled earlier. The guidance explains user-folder alerts, notification settings and foreground
suppression; it no longer promises notifications override these conditions. Added the verified behavior to
the glossary for the 11 remaining initial reviews. Also fixed adjacent Bulgarian agreement and Danish
punctuation. These followups do not add initial-scope catalog entries or help topics.

All 24 files preserve markup, attributes, platform branches and literal keys. Static structural checks have
no unexpected findings; exact pending inventories and completed/source hashes reconcile. Report regenerated;
git diff --check passes. No test suite was run. First late-review checkpoint: `d38c230c`.

Current totals: 17,481 catalog entries and 680 help pages reviewed; 2,732 catalog values improved. Remaining:
14,779 catalog entries and 572 help pages (including 138 late rollback entries). All recorded context
followups are complete. `REVIEWED` remains unchanged until the full round is complete.

Context to retain: the new languages were drafted before the last source corrections. Check the round-1 final
consistency findings when reviewing their encryption, transfer, attachment and folder-navigation text.

Additional context for later languages: a TLS-required server response does not prove the password valid;
a malformed message is unreadable by this app, not necessarily every mail app. Attachment opening uses an
external handler after saving a temporary copy. The sign-in-page-file switch writes a URL, not page HTML.
