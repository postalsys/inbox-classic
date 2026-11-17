# Translation review, round 2, November 2026

Review all newly added language drafts and later edits for fluent, natural wording in the actual app context.
Commit completed batches regularly and preserve an exact resume point.

## Resume here

- **Next: Czech compose additions.** Compose additions are complete in de, es, et, fr, nl, it, pt, pt-BR, ca, nb, sr-Latn, tr, bg.
  Each completed language has 40 new entries and both help targets reviewed. Exact IDs and context are
  recorded in `compose-sign-encrypt-context`; source feature `162c0dd2` was integrated in `3552434d`.
- Remaining compose languages: cs, da, el, fi, hr, hu, lt, lv, pl, ro, ru, sk, sl, sv, uk.
  Then finish 48 original Hungarian help topics and the broader lt/lv/pl/ro/ru/sk/sl/sv/uk drafts.
- Current scope: 33,868 catalog entries and 1,352 help topics.
  Completed: 21,191 entries and 816 full topics; pending: 12,677 entries and 536 topics.
  Historical catalog improvements: 3,742.
- All 28 active-key signature warnings are reviewed in `25eff7b8`. Source-only import `205bd846` includes
  catalogs/generated identifiers; implementation provenance is recorded separately.
- Structural checks, all 53 mnemonic scopes in completed compose languages, full inventories and current
  hashes reconcile. HTML refreshed. No test suites or builds run for wording batches; the earlier source-import
  build passed in the separate target. `REVIEWED` stays unchanged until the full queue and final audit finish.
- Latest source audit found no new strings/languages. Six source worktrees were also checked for uncommitted
  relevant changes. The 290 old untracked ca/nb/pt-BR/sr-Latn/tr files in PostalExpress-lang still match the
  imported initial snapshot `cfdf55ab` exactly. Recompare them with the recorded helper at later checkpoints.
- Individual recipients use green/blue locks and platform-specific lookup/warning symbols. The separate
  overall status bar uses the verified shield. Keep this distinction in future help edits.
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
- Upstream settings pages at `bd4a2bd1` are now integrated after Croatian app checkpoint `580d74a0`.
  German, Spanish, Estonian, French, Dutch, Italian, European/Brazilian Portuguese, Catalan, Norwegian
  Bokmål, Serbian Latin, Turkish, Bulgarian, Czech, Danish, Greek and Finnish settings are complete, including
  encrypted-image and rendered-label followups. The provider-app-password followup is now complete in all
  17 previously completed languages and Croatian, as is the no-Trash deletion followup. Only the ten
  broader language drafts still require those corrections. Fresh fetch at 27d00888 found all six source tips
  unchanged; origin/master remains 5c645187 with unrelated README/Linux test/CI changes left unmerged.
  No new translation/help or app-behavior changes. Fresh fetch at 0190587f confirms unchanged refs and guide.
  Croatian's catalogs and all 52 help topics are now reviewed, including the encryption/search additions.
  Its three prior settings-context followups are complete. Password troubleshooting is corrected in Croatian and
  the 17 previously completed languages; the ten broader drafts retain it.
- Encryption/search feature `38841d96`, observed in origin/master merge `08c9ef12`, is now integrated after
  reviewed checkpoint `3aa142c1`, committed as `c83a2e31`. All 18 earlier languages are caught up:
  de/es/et/fr/nl/it/pt/pt-BR/ca/nb/sr-Latn/tr/bg/cs/da/el/fi/hr. Croatian's seven original help topics and
  encryption additions are finished. The shared search-negation overclaim is corrected in all 18 languages;
  the ten broader drafts retain it within their existing marked search-words topic. Exact context/provenance
  is in `encryption-search-context` and `search-negation-context`.
  Hungarian app.ftl is complete: 647 entries, 83 improvements and all 46 shortcut scopes passing.
  Its remaining 450 core.ftl entries are now reviewed too, with 96 improvements.
  Help source `255205aa` from `chore/pgp-hardening` (observed at `80d02fcc`) is now integrated:
  one inserted passage in connections/data-storage/encryption-keys in every language and English. Every byte
  of prior reviewed prose is preserved. All 54 insertions in the 18 earlier languages are now reviewed.
  Ten broad drafts retain their full-topic marks, including the remaining 30 insertions. Hungarian
  help.ftl and platform catalogs (245 entries) are now reviewed; the new compose import above comes next.
  Exact source/retained-review provenance
  is in `key_help_source_integration` and `key-storage-autocrypt-context`. Preserve the source worktree's
  unrelated uncommitted UI/fuzz work. Only the help source commit was imported.
  Hungarian catalogs are complete for this checkout, along with add-account/gmail-outlook/main-window/layouts;
  48 help topics remain before the new compose import.
  Continue lt/lv/pl/ro/ru/sk/sl/sv/uk afterward. All prior context followups remain relevant to those drafts.
- The integration added 16 IDs, removed 13 and changed 11 per language, and changed 11 help topics in
  each of 28 languages. Affected completed entries were reopened; no new draft was marked reviewed.
  Previous review IDs/topics are preserved under `removed_`/`reopened_` fields. New round scope is
  32,720 catalog entries and 1,320 help topics; 12,078 entries and 516 topics remain in the integrated queue.
  Four round-1 agent-undo status strings now enter scope; all 18 earlier languages have that correction.
  The key help additions bring four round-1 topics into scope and reopen 50 counted topics; 30 full drafts
  already had the affected topics pending. Previously reviewed passages have not been discarded.
- The 13 completed new-language initial reviews and round-1 languages received this late review work.
  Finnish had 1,340 entries/52 topics reviewed, with 174 improvements. Croatian's 626 app entries plus
  one Windows button were initially reviewed with 74 improvements; its 24 app settings additions now have two
  further improvements. Croatian core.ftl has 128 improvements, and the remaining platform/help-title catalogs
  have 54 more. Four provider introductions have subsequent corrections. All 52 Croatian help topics and
  the encryption additions are now reviewed; the final catalog batch adds four improvements. Continue the
  ten broader language drafts in the order recorded above.
- All 168 rollback messages and 84 loading labels remain reviewed. Earlier logo-cache, attachment-reminder
  and watched-notification followups remain preserved. Use their verified context in new reviews.
- The three settings pages replace the former single Options mnemonic scope: use 46 actual scopes.
  They pass across the 19 languages with reviewed app catalogs; all three settings-page scopes pass
  across all 28 languages. This is structural validation, not linguistic review of the new drafts.
- Check the new Settings help against Windows behavior: Cancel discards uncommitted local settings and
  trusted-sender removals, but cannot undo a default-app choice in external Windows Settings. The English
  source incorrectly promises that it can; the context note is in state and the glossary.
- The isolated offline pe-ffi build passed in 9.41 seconds. All 76 imported implementation/generated
  paths match upstream. Structural checks, inventory and hashes pass; no test suite was run.
- Additional scope requested during review: Brazilian Portuguese (`pt-BR`), Turkish (`tr`), Norwegian Bokmål
  (`nb`), Catalan (`ca`) and Serbian Latin (`sr-Latn`). Found on local `feat/languages-wave1` at `cfdf55ab`,
  not yet on `master` or `origin/master`. They are included in the isolated review checkout;
  the feature implementation was initially isolated and has now reached origin/master at `76f67e82`.
  The translation review edits remain on the isolated review branch.
  This adds 6,655 catalog entries and 260 help topics: scope after that addition was 32,008 entries and 1,252 topics. The later loading labels add 84 entries,
  bringing that scope to 32,092 entries and 1,252 topics. The 168 later rollback messages increase
  that scope to 32,260 entries and 1,252 topics. The settings integration has a net increase of
  180 catalog entries and 40 help topics, bringing that scope to 32,440 entries and 1,292 topics. The provider
  context followup adds 16 previously out-of-scope catalog entries and four help topics, for 32,456 and 1,296.
  The no-Trash deletion followup adds four round-1 help topics, bringing the scope to 32,456 and 1,300.
  The password-troubleshooting followup adds four further round-1 topics, bringing it to 32,456 and 1,304.
  Other affected items were already counted and are reopened without increasing scope. The encryption batch
  adds 252 new IDs, four changed round-1 IDs and twelve round-1 help topics: scope is now 32,712 and 1,316.
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

### Late rollback reviews for the remaining completed languages

Reviewed 72 new messages in nl/it/pt/pt-BR/ca/nb/sr-Latn/tr/bg/cs/da/el, improving 35 values. Replaced literal
as-it-was descriptions with clear wording about undoing the requested change. Improved read-state wording,
Turkish passive constructions and Bulgarian folder names. Serbian and Brazilian Portuguese use exact `[1]`
where a standalone singular noun or pronoun means exactly one, keeping counted phrases valid for 21 or zero.
Czech five-or-more status adjectives agree with the counted phrase. The app restores rows after move/delete/
archive failure, and reverses a requested flag change when the server refuses it.

Static checks have no unexpected findings. Complete IDs and variables match English; plural/default branches,
exact pending inventories and completed/source hashes reconcile (17,605 messages and 9,122 changed help lines).
Report regenerated; git diff --check passes. No test suite was run. Sixty-six late messages remain in the 11
languages whose initial reviews are still pending. Notification followup checkpoint: `d70398ad`.

### All late rollback messages completed

Reviewed the final 66 rollback messages in hr/hu/lt/lv/pl/ro/ru/sk/sl/sv/uk and their 11 shared counted-message
phrases, improving 46 values. Corrected standalone singular references at 21/101, preserved direct agreement
with counted phrases and Slovenian dual forms, clarified restored read states and reversed flag changes, and
used actual-folder head nouns without inflecting names. Updated glossary context and Latvian folder guidance.

All 168 late messages are now reviewed across 28 languages. Static checks have no unexpected findings;
complete catalog IDs/variables, exact pending marks and completed/source hashes reconcile (17,682 messages
and 9,122 changed help lines). Report regenerated; git diff --check passes. No test suite was run.
Fresh fetch: origin/master remains `46b938a7`, local master `5573ee4b`, local/remote wave1 `8df686a4`.
No new localization/help/command changes or languages; --since-start reports zero newly pending entries or
passages. Begin Croatian app.ftl. Each of the remaining 11 languages has 1,330 catalog entries and 52 help
topics left. Previous late-review checkpoint: `4a5719cb`.

### Croatian app catalog and new settings source discovered

Reviewed all 626 shared app entries and the coupled Windows Save As button, improving 74 values. Corrected
literal commands, queued agent state, rule processing, counted contact imports, dynamic names, account-transfer
credentials, key fingerprints/ownership, and cached sender images. All 44 actual mnemonic scopes are free of
collisions; Windows and GTK Cc/Bcc retain Alt+K/Alt+S. Existing Linux rules/contact screenshots supplied layout
context; no Croatian tour screenshots are available. The generic sign-in accessibility label changed, without
changing branded image labels. Glossary decisions are recorded for the remaining Croatian catalogs/help.

Static checks show exactly 637 deliberately removed catalog marks, with no structural findings. Full IDs,
variables, plural branches, comments and access-key counts are preserved. All 28 language inventories match
state; completed/source hashes reconcile (18,309 messages and 9,122 changed help lines). Report regenerated;
git diff --check passes. No test suite was run. Previous checkpoint: `b00052c8`.

The fresh upstream comparison found settings-page work at `bd4a2bd1`, following `46b938a7`. Across the 28
translations, it adds 448 catalog IDs, removes 364, changes 308 existing values and changes 308 help topics.
No new languages were found. These changes are not yet integrated; the state contains the exact per-file ID
and help-topic inventory. Integrate them next, preserve review corrections, and reopen affected completed
content against the new settings layouts. The --since-start check reports zero newly pending strings in the
current checkout, which does not include this unmerged upstream delta.

### Settings source integrated; affected work reopened

Integrated `bd4a2bd1` into the isolated review branch, resolving 182 translation/help conflicts. All unchanged
reviewed catalog values and the prose of ten help topics per language were retained; their settings paths now
use the new `data-settings` control. The expanded Settings topic retains reviewed blocks where unchanged or
extended, with new/reworked blocks left as drafts. Preserved notification conditions and logo-cache corrections.
The sender-image subtitle retains the reviewed wording and is reopened for the new column-layout context.

Across 28 languages, 448 new IDs are pending, 364 obsolete platform IDs were removed, and 308 changed IDs
are pending. This reopened 197 completed entries. All 308 affected help topics are pending, reopening 187.
The round's net scope grows by 180 catalog entries and 40 help topics; exact inventories explain round-1
items entering this round, and historical removed/reopened reviews remain recorded.

All 28 language IDs, full variable sets, access-key counts, help topics and pending marks reconcile. Every help
control and settings-page reference resolves. Static check-language has only 23,796 deliberately removed-mark
diagnostics; upstream fixed the seven former es/fr parser false positives. All three settings-page access-key
scopes pass across 28 languages; all 46 actual scopes pass in the 18 languages with reviewed app catalogs.
The dedicated offline pe-ffi build passed (9.41 seconds), and all 76 imported implementation/generated paths
match upstream. Completed/source hashes reconcile (17,983 messages and 7,311 changed help lines). No tests run.

Review the settings translations and 11 topics in de/es/et/fr next. Correct the Windows Cancel/default-app
source claim using the new glossary context note. The previous Croatian checkpoint is `580d74a0`.

### German settings review completed

Reviewed all 27 new/changed catalog entries and all 11 affected help topics. Retained the sound labels and
added the column-layout condition to the sender-image subtitle. Rewrote the expanded Settings help for natural
German and the actual Apply/Cancel, default-app, send-delay and image-download behavior. Improved conversation
phrasing, path joins and sign-in-code domain authentication wording. The available GTK screenshot predates the
redesign; current page structure was checked against settings.toml and the platform callers.

All 46 mnemonic scopes pass. Static check-language reports only 1,395 deliberately removed marks; markup,
controls, platform branches, literal keys, catalog variables and comments are preserved. All 28 pending
inventories and completed/source hashes reconcile (18,006 messages and 7,351 changed help lines). Four unchanged
English/translation pairs moved from removed baseline IDs and are correctly omitted by the report; each was
independently matched to the complete baseline values, and remains in the completed inventory. The helper now
verifies such moves explicitly. Report regenerated; git diff --check passes. No tests run.

Continue es/et/fr settings next. Source integration checkpoint: `31b96b81`.

### Spanish settings review completed

Reviewed all 27 settings catalog entries and 11 affected help topics, improving three catalog values.
Clarified the restart prompt, background-only notice and column-layout image description. Rewrote Settings
help in formal Spanish, with natural defaults and accurate Apply/Cancel, external default-app choices,
queued sending, notification dependency and image-download conditions. Improved conversation descriptions,
sorting-criterion wording and code-card domain authentication. Existing notification/cache corrections remain.

All 46 mnemonic scopes pass. Static check-language reports only 1,395 deliberately removed marks, no
structural findings. Help markup, controls, platform branches and literal keys are preserved, as are catalog
IDs, variables, access-key counts and comments. All 28 pending inventories and completed/source hashes
reconcile (18,030 messages and 7,393 changed help lines). Three Spanish moved baseline pairs join the four
German pairs independently verified by the helper. Report regenerated; git diff --check passes. No tests run.

Continue Estonian and French settings next. German settings checkpoint: `a2b509e0`.

### Estonian settings review completed

Reviewed 27 catalog entries and all 11 affected help topics, improving six catalog values. Used "Uued kirjad"
for the notification group and "teatis" for notifications, clarified the per-account disk-space limit,
improved image-download and update wording, and added the column-layout condition to the sender-image note.
Rewrote Settings help in polite Estonian with accurate Apply/Cancel, external default-app behavior, queued
sending, defaults and image conditions. Improved settings navigation, conversation rows, failed-send/retry
wording, mailto fields, quoted-message folding and code-card authentication. Glossary decisions are recorded.

All 46 mnemonic scopes pass, including the new storage-label access key. Static check-language reports only
1,395 deliberately removed marks. IDs, variables, access-key counts, comments, help tags/attributes, OS branches
and literal shortcuts are preserved. All 28 pending inventories and completed/source hashes reconcile
(18,053 messages and 7,449 changed help lines). Four Estonian moved baseline pairs join the seven already
verified for German/Spanish. Report regenerated; git diff --check passes. No tests run.

Continue French settings next. Spanish settings checkpoint: `64101fe2`.

### French settings review completed

Reviewed 27 catalog entries and all 11 affected help topics, improving two catalog values. Added the column-layout
condition to the sender-image note and corrected the background-condition elision. Retained fluent settings labels.
Rewrote Settings help with accurate Apply/Cancel, external Windows default-app behavior, queued sending, defaults
and image conditions. Improved conversation rows, retry wording, sorting criteria, background operation and
code-card authentication while preserving earlier notification and persistent logo-cache corrections.

All 46 mnemonic scopes pass. Static check-language reports only 1,395 deliberately removed marks. IDs, variables,
access-key counts, comments, help tags/attributes, OS branches and literal shortcuts are preserved. All 28 pending
inventories and completed/source hashes reconcile (18,077 messages and 7,497 changed help lines). Three French
moved baseline pairs join the 11 already verified for German/Spanish/Estonian. Report regenerated; git diff --check
passes. No tests run. Estonian checkpoint: `1e4fd054`; French checkpoint: `3ff603ac`.

Fresh upstream fetch after French found no new languages or unintegrated catalog/help/settings changes.
Origin/master remains `bd4a2bd1`, master `5573ee4b`, and local/remote languages-wave1 `8df686a4`. All 28
inventories and exact pending marks match. The captured since-start report has the 648 known settings entries
and 264 help passages in 24 languages, with no additional work. Continue Dutch settings; repeat the source
audit after the remaining queue is completed.

### Dutch settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving two catalog values. Made the language-restart
prompt natural and added the column-layout condition to the sender-image note. Rewrote Settings help in the established
informal style with accurate Apply/Cancel, external default-app behavior, queued sending, exact download defaults and
image/domain conditions. Improved collapsed-conversation actions, file association, main-window notifications,
image blocking and code-card authentication. Retained fluent wording and prior logo-cache corrections elsewhere.
No Dutch screenshots were available; current settings layout and behavior were checked in source.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes, catalog invariants,
help markup and exact 28-language pending inventories pass. Completed/source hashes reconcile with 18,104 messages
and 7,642 changed help lines; 14 moved baseline pairs remain verified. Report regenerated; git diff --check passes.
No tests run. Continue Italian settings next.

### Italian settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving three catalog values. Improved restart wording,
the sender-image note and automatic-update label. Rewrote Settings help with natural wording for defaults and accurate
Apply/Cancel, external default-app choices, queued sending, exact download defaults and image/domain conditions.
Improved logo fallback, download-option joins, retry wording, sorting instructions, main-window notifications,
background operation and code-card authentication. No Italian screenshots were available; current settings verified
from source. Encrypted message parts still require explicit permission to load external images, even with automatic
loading enabled (`view.rs`). Italian help now states this exception and the glossary records it for future batches.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes, catalog invariants,
help markup and exact 28-language pending inventories pass. Completed/source hashes reconcile with 18,131 messages
and 7,787 changed help lines; 14 moved baseline pairs remain verified. Report regenerated; git diff --check passes.
No tests run. Dutch checkpoint: `2a52474b`. Add the image exception to de/es/et/fr/nl settings/image help, then Portuguese.

### Encrypted-image permission followup completed

Clarified the settings and image-loading help in German, Spanish, Estonian, French and Dutch: encrypted message
parts still require explicit permission to load external images. Italian already has this wording. All 10 edits
preserve surrounding text, tags, attributes, platform branches and shortcuts. Each language’s static checker reports
only the 1,395 deliberate missing marks; inventories and completed/source hashes reconcile. Global totals remain
18,131 unmarked messages and 7,787 changed help lines, with 14 verified moved baseline pairs. Report regenerated;
git diff --check passes. No tests run. These are followups on completed topics and do not inflate completion totals.

State tracks the exception for the 22 remaining settings languages under `encrypted-image-permission`. Complete
that followup alongside `settings-pages-context` when each language is reviewed. Continue Portuguese settings.
Italian checkpoint: `5bfb208c`.

### European Portuguese settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving two catalog values. Improved the restart
prompt and added the column-layout condition to the sender-image note. Rewrote Settings help in European Portuguese
with natural default wording, correct Apply/Cancel and external default-app choices, queued sending, exact download
defaults and image/domain conditions. Clarified encrypted-image permission, logo reuse, the storage limit,
download-option joins, background operation, quoted-message folding and code-card authentication/expiry. Retained
fluent prior corrections. No Portuguese screenshots were available; current settings were checked against source.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes and structural checks
pass. Exact pending inventories and completed/source hashes reconcile (18,158 messages and 7,932 changed help lines);
14 moved baseline pairs remain verified. Report regenerated; git diff --check passes. No tests run.

Fresh fetch at baac8a3b confirmed unchanged source refs, no new languages or unintegrated source changes. The
captured since-start report contained the 594 already pending settings entries and 242 passages in 22 languages,
with no additional work. Continue Brazilian Portuguese; complete both settings and encrypted-image followups.

### Brazilian Portuguese settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving three catalog values. Used “Aplicativos padrão”
for the group heading, improved the restart prompt and added the column-layout condition to the sender-image note.
Rewrote Settings help with natural defaults, accurate Apply/Cancel and external default-app choices, queued sending,
exact download defaults and image/domain conditions. Improved conversation/brand prose, installed-app wording,
download-folder meaning, attachment terminology, background operation and code-card authentication/expiry.
Fixed “clique em no botão” in Mac/Linux reading help and inspected the joined sentence on all three platforms.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes and structural checks
pass. Exact inventories and completed/source hashes reconcile (18,185 messages and 8,077 changed help lines), with
14 verified moved baseline pairs. Report regenerated; git diff --check passes. No tests run. European Portuguese
checkpoint: `085f2668`.

The help renderer strips trailing colons from catalog labels. Brazilian Portuguese download help now supplies its
own separator; fix the same missing separator in de/es/et/fr/it/pt before Catalan. Dutch already has a full sentence.
The glossary records the renderer behavior for later reviews.

### Rendered download-label punctuation followup completed

Added explicit separators after the download-field label in German, Spanish, Estonian, French, Italian and European
Portuguese. The renderer removes the catalog colon, so the original help ran the label into the following sentence.
Adjusted capitalization and preserved the French nonbreaking space before the colon. Dutch already has a full
sentence; Brazilian Portuguese was corrected in its settings batch. These six edits do not add completion counts.

All six check-language runs report only the 1,395 deliberate missing marks. Exact markup and other text are preserved;
joined sentences were inspected with substitutions matching the renderer. Completed/source hashes reconcile with
18,185 unmarked messages and 8,080 changed help lines, including 14 verified moved baseline pairs. Report regenerated;
git diff --check passes. No tests run. Brazilian Portuguese checkpoint: `6605b96a`.

Continue Catalan. In each later language, complete `settings-pages-context`, `encrypted-image-permission` and
`help-label-punctuation` together; the latter two concern topics already pending in the settings queue.

### Catalan settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving three catalog values. Aligned the default-app
group heading with “Aplicacions predeterminades”, clarified column-layout images and used the Mac’s established
infinitive for automatic updates. Retained vós in prose and imperative shared controls. Rewrote Settings help with
consistent language terminology, accurate Apply/Cancel, external default-app behavior, queued sending, exact download
defaults and image/domain conditions. Improved conversation rows, installed-app wording, draft attachments/saving,
retry and background operation, and code-card authentication/expiry. Included the encrypted-image exception and
explicit download-label punctuation. No Catalan screenshots were available; current layout/behavior checked in source.

Static check-language reports only 1,395 intentionally removed marks. All 46 shortcut scopes and structural checks
pass. Reading-help joins for all three platforms and the download-label sentence were inspected after substituting
labels as the renderer does. Exact inventories and completed/source hashes reconcile (18,212 messages and 8,225
changed help lines), with 14 verified moved baseline pairs. Report regenerated; git diff --check passes. No tests run.

Continue Norwegian Bokmål settings, then Serbian Latin, Turkish, Bulgarian, Czech, Danish, Greek, Finnish and the
Croatian app additions before the remaining initial reviews. Nine languages have completed all three settings-context
followups; 19 remain. Label-punctuation followup checkpoint: `7bc58321`.

### Norwegian Bokmål settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving one catalog value. Added the column-layout
condition and established Adressebok name to the sender-image note; retained fluent labels. Rewrote Settings help
with accurate Apply/Cancel, external default-app choices, queued sending, exact download defaults and image/domain
conditions. Corrected trusted-sender meaning, collapsed-conversation actions, installed-app wording, large-message
downloads, draft attachments/compose windows and background operation. Clarified domain signatures, encrypted-image
permission and download-label punctuation. Retained direct du prose and earlier notification/logo-cache corrections.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes, catalog invariants and
help markup pass. Three platform reading-help joins and the download-label sentence were inspected after control
substitution. Exact inventories and completed/source hashes reconcile (18,239 messages and 8,370 changed help lines),
with 14 verified moved baseline pairs. Report regenerated; git diff --check passes. No tests run.

Fresh fetch at Catalan checkpoint `42a456a9` confirmed unchanged refs and no new languages or unintegrated source
changes. Since-start contains the 513 known settings entries and 209 passages in 19 languages, with no extra work.
Continue Serbian Latin. Ten languages have completed all three settings-context followups; 18 remain.

### Serbian Latin settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving three catalog values. Improved the restart
prompt, clarified the per-account storage limit and added column-layout context to the sender-image note. Retained
Ekavian, formal plural prose and imperative singular controls. Rewrote Settings help with accurate Apply/Cancel,
external Windows default-app choices, queued sending, exact download defaults and image/domain conditions. Improved
conversation actions, logo fallback, download-label punctuation, large-message downloads, attachment/compose-window
wording and background operation. Corrected settings navigation and clarified encrypted-image permission and
code-card domain signatures. The intentional English macOS system path is preserved.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes and structural checks
pass. Three platform reading-help joins and the download-label sentence were inspected with renderer-style
substitution. Exact inventories and completed/source hashes reconcile (18,266 messages and 8,515 changed help lines),
with 14 verified baseline pairs. Report regenerated; git diff --check passes. No tests run. Norwegian checkpoint:
`17d07993`. Continue Turkish; 11 languages have completed all three settings-context followups and 17 remain.

### Turkish settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving four catalog values. Improved the restart
prompt, moved two access keys off dotted I and added column-layout context to the sender-image note. Retained polite
siz prose and established terms. Rewrote Settings help with natural defaults, accurate Apply/Cancel, external Windows
default-app choices, queued sending, exact download defaults and image/domain conditions. Refined page navigation,
conversation actions, logo fallback, attachment/compose-window wording and background operation. Clarified code-card
domain signatures and expiry, encrypted external-image permission and rendered download-label punctuation.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes pass, with an additional
check for dotted/dotless I. Catalog invariants and exact help markup pass. Relevant platform/control joins were
inspected after renderer-style substitution. Exact inventories and completed/source hashes reconcile (18,293 messages
and 8,660 changed help lines), with 14 verified baseline pairs. Report regenerated; git diff --check passes. No tests run.

Fresh fetch at Serbian checkpoint `426b66c3` confirmed unchanged refs and no new languages or unintegrated source
changes; local more-languages/settings-pages branches also have no additional relevant changes. The since-start report
contains 432 known settings entries and 176 passages in 16 languages, each matched to the pending inventory. Continue
Bulgarian; 12 languages have completed all three settings-context followups and 16 remain.

### Bulgarian settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving four catalog values. Aligned Apply with
noun-style controls, improved the restart prompt, clarified the per-account storage limit and added column-layout
context to the sender-image note. Retained polite lowercase вие, feminine Inbox Classic and Cyrillic access keys.
Rewrote Settings help with natural defaults, accurate Apply/Cancel, external Windows default-app choices, queued
sending, exact download defaults and image/domain conditions. Improved collapsed conversations, logo fallback,
attachment/compose-window wording, retry behavior and background operation. Clarified code-card domain signatures
and encrypted external-image permission, added download-label punctuation and grammatical option references, and
quoted long control labels in reading help. The intentional English macOS system path is preserved.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes and structural checks
pass. Relevant control/platform joins were inspected after renderer-style substitution. Exact inventories and
completed/source hashes reconcile (18,320 messages and 8,805 changed help lines), with 14 verified baseline pairs.
Guide and source tips remain unchanged since the fresh Turkish audit. Report regenerated; git diff --check passes.
No tests run. Turkish checkpoint: `3d26d46f`. Continue Czech; 13 languages have completed all three settings-context
followups and 15 remain.

### Czech settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving four catalog values. Improved the restart
prompt, clarified the per-account storage limit, added column-layout context and aligned notification terminology
with the help. The glossary records oznámení for the noun and upozornit for the verb. Rewrote Settings help with
accurate Apply/Cancel, external Windows default-app choices, queued sending, exact defaults and image/domain
conditions. Improved logo fallback, installed-app wording, storage totals, large-message downloads, compose windows,
background operation and code-card domain signatures. Retained fluent prior text. Added encrypted external-image
permission and download-label punctuation, resolved case agreement around settings paths and quoted long labels.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes and structural checks
pass. Relevant control/platform joins were inspected after renderer-style substitution. Exact inventories and
completed/source hashes reconcile (18,347 messages and 8,950 changed help lines), with 14 verified baseline pairs.
Report regenerated; git diff --check passes. No tests run.

Fresh fetch at Bulgarian checkpoint `1df91cf1` confirmed unchanged refs and no new languages or unintegrated relevant
source changes. The since-start report contains 405 known settings entries and 165 passages in 15 languages, each
matched to the pending inventory at that checkpoint. Continue Danish; 14 languages have completed all three
settings-context followups and 14 remain.

### Danish settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving one catalog value. Kept fluent labels and du
prose; added column-layout context and natural logo-reuse wording to the sender-image note. Rewrote Settings help
with accurate Apply/Cancel, external Windows default-app choices, queued sending, exact defaults and image/domain
conditions. Improved conversation actions, logo fallback, installed-app wording, compose-window closure, Outbox
status and background operation. Distinguished embedded from external images, clarified code-card domain signatures
and expiry at opening, and added encrypted external-image permission. Download help uses a grammatical sentence
around its labels; removed repetition exposed by the inserted 30-day label. Removed a genitive ending on Gmail and
quoted the long dark-mode label. Relevant control/platform joins were inspected after renderer-style substitution.

Static check-language reports only 1,395 deliberately removed marks. All 46 shortcut scopes and structural checks
pass. Exact inventories and completed/source hashes reconcile (18,374 messages and 9,095 changed help lines), with
14 verified baseline pairs. Guide and all six source tips remain unchanged since the fresh Czech audit. Report
regenerated; git diff --check passes. No tests run. Czech checkpoint: `95a08e03`. Continue Greek, then Finnish and
Croatian app additions. Fifteen languages have completed all three settings-context followups and have no pending
catalog/help work; thirteen languages remain.

### Greek settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving four catalog values. Improved the restart
prompt, moved two access keys to unaccented letters and added column-layout context to the sender-image note.
Rewrote Settings help with polite plural, natural defaults, accurate Apply/Cancel, external Windows default-app
choices, queued sending, exact download defaults and image/domain conditions. Restored the address-book fallback,
clarified collapsed conversations, conditional downloading, attachment/compose-window wording, Outbox status and
background operation. Clarified code-card domain signatures and encrypted external-image permission, including
trusted senders. Improved settings-page references and quoted the long dark-mode label. Relevant control/platform
joins were inspected after renderer-style substitution; download help supplies punctuation outside its controls.

Static check-language reports only 1,395 deliberately removed marks. All 46 mnemonic collision scopes and structural
checks pass. Explicit catalog access keys are unaccented. The app's generated flag-menu algorithm can choose accented
ί for Κίτρινο after Κ is used for Κόκκινο; this app-side limitation is recorded in the glossary and state. Correct colour
spelling is retained. Collision checks do not establish runtime usability; no app code changed or runtime test run.

Exact inventories and completed/source hashes reconcile (18,401 messages and 9,240 changed help lines), with 14
verified baseline pairs. Report regenerated; git diff --check passes. No tests run. Fresh fetch at Danish checkpoint
`7d4b4c3b` confirmed unchanged refs and no new languages or unintegrated relevant source changes. The since-start
report contains 351 known settings entries and 143 passages in 13 languages, each matched to the checkpoint inventory.
Continue Finnish, then Croatian app additions. Sixteen languages have completed all three settings-context followups
and have no pending catalog/help work; twelve languages remain.

### Finnish settings review completed

Reviewed all 27 settings entries and 11 affected help topics, improving three catalog values. Improved the restart
prompt and global-image label, and added column-layout context plus the established tuotemerkin logo term to the
sender-image note. Retained fluent labels and informal singular instructions. Corrected Windows Apply/Cancel and
external default-app choices, immediate Mac/Linux changes except language restart, the ten-second send delay,
exact download defaults and conditions, collapsed conversations and authenticated sender images. Clarified compose
windows, queued messages, background operation, domain signatures and encrypted external-image permission including
trusted senders. Preserved earlier logo-cache and notification corrections. Improved settings-page references,
quoted long labels and removed the repeated size limit revealed by inserting the actual download option label.

Static check-language reports only 1,395 deliberately removed marks. All 46 mnemonic scopes and structural checks
pass. Relevant reading/download/default-app and settings joins were inspected with renderer-style substitution on
all three platforms. Exact inventories and completed/source hashes reconcile (18,428 messages and 9,385 changed
help lines), with 14 verified baseline pairs. Guide and all six source tips are unchanged since the Greek audit.
Report regenerated; git diff --check passes. No tests run. Greek checkpoint: `428f3f97`. Continue Croatian app
additions, then its remaining initial reviews. Seventeen languages have completed all three settings-context
followups and have no pending catalog/help work; eleven languages remain.

### Croatian app settings additions completed

Reviewed all 24 new/changed Croatian app settings entries, improving two values. Improved the restart prompt with
natural formal-plural wording and an uninflected language placeholder. Added column-layout context to the sender-image
note, keeping authenticated-domain meaning, Address Book fallback and persistent logo reuse; improved clitic placement.
Other labels are fluent and unchanged. The glossary now records the 46 current shortcut scopes. All remaining Croatian
catalogs and its 52 help topics stay pending; the three settings followups remain open until their relevant work is done.

Static check-language reports only 651 deliberately removed marks, with no structural findings. All 46 mnemonic scopes,
IDs, variables, access-key counts, comments and dash checks pass. Exact inventories and completed/source hashes reconcile
(18,452 messages and 9,385 changed help lines), with 14 verified baseline pairs. Report regenerated; git diff --check
passes. No tests run. Fresh fetch at Finnish checkpoint `381572d9` confirmed unchanged refs and no new languages or
unintegrated relevant source changes. The since-start report contains 297 known settings entries and 121 help passages
in 11 languages, each matched to the checkpoint inventory. Continue Croatian core.ftl, then the remaining catalogs/help.

### Croatian core catalog completed

Reviewed all 448 pending core entries, improving 128 values. Read the actual callers for selection/deletion counts,
transfer/export progress, bounce cards, sign-in failures, calendar recurrence, agent permissions/logs, OTP cards,
OpenPGP, setup import and attachment handling. Improved natural explanations and formal-plural instructions. Kept
independent counters and already-counted message phrases grammatically safe, including fallback folder names. Transfer
progress names the current attempt, without claiming that it completed. Calendar intervals use nominative counted
phrases after a descriptive label, preserving exact-one forms and avoiding forced agreement around 21/31.

Agent logs now distinguish queuing from sending; permissions describe access through Inbox Classic. Clarified key
ownership versus signature validity, decryption versus encryption, private-key backup recovery and confirmation of
every published address. Setup files use datoteka s postavkama, matching the reviewed app controls. The shared
unreachable-service message fits account and app names. Corrected the attachment-copy note to describe unencrypted
copies and cleanup at app startup. Glossary notes retain these decisions for the help review.

Static check-language reports only 1,099 deliberately removed marks, with no structural findings. All 46 mnemonic
scopes, catalog invariants, comments and dash checks pass. Plural structures and all variables are preserved; reviewed
representative count/name substitutions against their callers. Exact inventories and completed/source hashes reconcile
(18,900 messages and 9,385 changed help lines), with 14 verified baseline pairs. Guide and all six source tips remain
unchanged since the fresh Croatian audit. Report regenerated; git diff --check passes. No tests run. Croatian app
checkpoint: `17fbe28a`. Continue the 244 platform/help-title entries and 52 help topics. Croatian is not yet complete.

### Croatian platform catalogs completed

Reviewed all 244 remaining help-title and Windows/Mac/Linux catalog entries, improving 54 values. Corrected
Linux Preferences to Postavke and clarified help sections. Kept native Mac menu conventions and all shortcuts.
Indexing messages identify remaining work, and failed-file summaries handle failed and total counts independently.
Clarified agent-entry removal, server-side folder deletion, Windows user-account installation and preservation of
server mail. Improved browser sign-in, credential warnings and image-blocking language. Store text now describes
hidden quoted text and downloaded offline mail accurately. All Croatian catalogs are reviewed; all 52 help topics
and its three settings-context followups remain pending.

Static checks report only 1,343 deliberately removed marks. All 46 mnemonic scopes and catalog invariants pass;
all 28 inventories and latest file/source hashes reconcile (19,144 messages and 9,385 changed help lines, with 14
verified baseline pairs). The isolated offline pe-ffi build passed in 5.81 seconds; generated installer/Linux
changes affect only Croatian. The requested HTML report is regenerated. No tests run. git diff --check passes.
Source limitation recorded: the Linux search scope receives English special-folder names from Query::place_name;
the catalog cannot localize this dynamic value. It needs an app-side followup. No app code or English changed.

Fresh fetch at `675fb1f2` confirms unchanged six source refs, no new languages or unintegrated relevant changes.
The since-start report contains 270 known settings entries in ten languages and 121 help passages in eleven,
all matched to the current pending inventory. Continue Croatian help; repeat the late-arrival audit after the queue.

### Croatian first eight help topics and provider-context followup

Reviewed add-account, gmail-outlook, main-window, layouts, read-messages, find-messages, conversations and
organize-mail. Improved formal instructions and control joins; corrected combined-folder order and collapsed
unread totals, quoted-text folding, automatic search indexing and watched-notification conditions. Preserved all
markup, attributes, platform branches, settings/control references and literal keyboard tags. Croatian has 44 help
topics left; its three settings-context followups are still pending.

The app's existing MICROSOFT_WARNING and official provider guidance confirm that Outlook.com and Microsoft 365
mail require browser/modern authentication. App passwords are not an alternative; Google permits them only on
eligible accounts with two-step verification. Corrected the Croatian help and four provider introductions.
Sources: [Microsoft mail settings](https://support.microsoft.com/en-gb/outlook/pop-imap-and-smtp-settings-for-outlook-com),
[Exchange Online authentication](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-basic-authentication-exchange-online),
[Google app passwords](https://support.google.com/accounts/answer/185833?hl=hr).

Recorded the focused provider-app-password-context followup: 60 catalog entries and three help passages in each
of 17 previously completed languages are marked for re-review. Their wording is unchanged at this checkpoint.
Bulgarian/Turkish introductions already condition app-password support and remain reviewed; their Microsoft help
steps still need correction. Existing pending drafts include the same targets. Only 16 entries and four topics
from the round-1 languages are new to the active scope. Prior reviews and unchanged passages are retained; the
reconciliation helper verifies partial-topic content byte-for-byte against the pre-reopen Git checkpoint.

Static Croatian checks report 1,351 deliberately removed marks and no structural findings. All 46 shortcut scopes
pass. All 28 inventories and completed/source hashes reconcile (19,100 unmarked messages and 9,467 changed help
lines, plus 14 verified baseline pairs). The review report is regenerated and git diff --check passes. No tests
run. Fresh fetch at `5e4fd524` found no new source work; 318 known entries and 169 passages in the since-start
report match the queue. Another 12 reopened cs/da/nl catalog entries are unchanged from their initially marked
snapshot and therefore omitted by --since; their full English/translation pairs were verified and remain pending.
The larger queue comes from this context finding, not new upstream commits.

### German, Spanish, Estonian and French provider followup completed

Reviewed and corrected the four provider introductions and Gmail/Outlook help in each language: 16 catalog
entries and four help topics. Kept formal forms of address and established terms. Microsoft mail explicitly
requires browser sign-in; app passwords are conditional on account support. Help now limits those steps to
eligible Google accounts, explains two-step verification, and removes the incorrect Microsoft app-password path.
Adjusted the nearby heading and Google-button note for coherent instructions. Other reviewed prose is retained.

Structural checks report only 1,395 deliberately removed marks per language. All 46 shortcut scopes pass.
Markup, attributes, variables, controls, platform branches and literal keys are preserved. Relevant substituted
control joins and provider fallbacks were inspected. All inventories and completed/source hashes reconcile:
19,116 unmarked messages, 9,487 changed help lines and 14 verified baseline pairs. Guide and six refs remain
unchanged since the fresh audit. Report regenerated; git diff --check passes. No tests run.

German, Spanish, Estonian and French have no pending content again. Continue the same focused followup in
nl/it/pt/pt-BR/ca/nb/sr-Latn/tr/bg/cs/da/el/fi, then Croatian's 44 remaining help topics. The broader pending
languages will receive this context correction during their normal reviews. Previous checkpoint: `53ccd506`.

### Dutch, Italian and both Portuguese provider followups completed

Reviewed four provider introductions and Gmail/Outlook help in each language: 16 catalog entries and four
help topics, with all 16 catalog values improved. Microsoft mail explicitly uses browser sign-in; Google
app-password steps require an eligible account and two-step verification. Removed the incorrect Microsoft
app-password path and aligned the nearby heading and Google-button note. Preserved Dutch je, Italian tu,
polite European Portuguese and Brazilian você, together with their established terms and provider fallbacks.

Structural checks report only 1,395 deliberately removed marks per language, with all 46 shortcut scopes passing.
Markup, attributes, variables, controls, platform branches and literal keys are preserved. Substituted control
joins and provider fallbacks were inspected. All 28 inventories and completed/source hashes reconcile:
19,132 unmarked messages, 9,499 changed help lines and 14 verified baseline pairs. Report regenerated;
git diff --check passes. No tests run. Previous checkpoint: `45d95ce9`.

Fresh fetch found origin/master advanced to `154e0f6d`, adding only Linux regional-date tests and CI setup.
Inspected all four changed paths; these unrelated changes remain unmerged. Other five refs and the guide hash
are unchanged. No new languages or translation/help/app-behavior changes. The since-start report contains
290 known entries and 145 passages, all matched to pending inventory. Eight reopened Czech/Danish pairs are
omitted by --since because they equal their marked starting snapshots; verified separately. The four previously
omitted Dutch entries are now corrected and reviewed. Continue ca/nb/sr-Latn/tr/bg/cs/da/el/fi, then Croatian help.

### Provider followup completed in the remaining nine reviewed languages

Reviewed Catalan, Norwegian Bokmål, Serbian Latin, Turkish, Bulgarian, Czech, Danish, Greek and Finnish:
32 catalog entries and nine help topics, improving all 32 catalog values. Turkish's four introductions already
condition account support and remain unchanged. Reassessing Bulgarian found provider-wide support too broad
for Microsoft mail; reopened and corrected its four introductions without increasing scope. The net pending
catalog reduction is 28, because those Bulgarian entries were already counted as reviewed before this batch.

Microsoft mail uses browser sign-in. Google app-password steps now require an eligible account and two-step
verification; incorrect Microsoft menu paths are removed. Preserved each language's form of address and terms,
including Turkish Google's own şifre label inside otherwise consistent parola prose and Serbian explanations
beside the existing English Google labels. Norwegian app-passord agrees with the
[official Google wording](https://support.google.com/accounts/answer/185833?hl=no). Improved account-window
sentence joins in Catalan, Norwegian, Bulgarian and Danish after substituting the actual control titles.

All nine static checks report only 1,395 deliberately removed marks per language; all 46 shortcut scopes pass.
Variables, markup, attributes, control references, platform branches and literal keys are preserved. Inspected
substituted control/topic joins and provider fallbacks. All 28 inventories and completed/source hashes reconcile:
19,160 unmarked messages, 9,526 changed help lines and 14 verified baseline pairs. Report regenerated;
git diff --check passes. No tests run. Previous checkpoint: `09aa4b57`.

Fresh fetch found origin/master at `5c645187`, adding README documentation updates. Inspected them; the total
unmerged delta is README plus the four previously checked Linux date-format test/CI paths. These unrelated
changes remain unmerged. Other five source refs and the guide hash are unchanged. No new language or translation/
help/app-behavior work. All 270 entries and 118 passages in the since-start report match the pending inventory.
The formerly omitted Czech/Danish/Dutch provider introductions are now all corrected and reviewed.

### Croatian mail-task help and deletion behavior

Reviewed eight more Croatian help topics: message-rules, delete-and-undo, folders, write-message,
reply-forward, attachments, drafts-outbox and signatures. Improved natural Croatian instructions and
named-control joins against the actual rule editor, folder tree, composer, attachment handling and send queue.
Clarified cumulative rules, top-level folders, Reply All recipients, hidden quotations, supported attachment-
reminder languages, temporary unencrypted attachment copies and startup cleanup. Draft and Outbox help now
distinguishes retries from successful delivery, the default 10-second delay, Undo Send during that delay and
sending when quitting the app. Signature help describes automatic placement and account switching accurately.

Found a shared source omission: Delete can permanently remove a message when its account has no Trash folder.
Verified Core::delete_messages/trash_for/deletes_for_good, selection summaries and confirmation callers on all
three platforms. Corrected Croatian and reopened the first two deletion-help paragraphs in the 17 previously
completed languages. All 17 focused corrections are now complete; each topic's other content is unchanged.
Four round-1 topics enter the active scope; other reopened topics are not counted twice. The ten broader drafts
retain this followup for their normal reviews. English and app code are unchanged; the glossary records the issue.

Croatian's static check reports only 1,359 deliberately removed marks; each other language reports 1,395.
No structural findings; all 46 shortcut scopes pass. Exact tags, attributes, platform branches and literal keys
are preserved. Inspected substituted controls, settings paths and topic-title joins, correcting a Catalan
folder-name join. These previews do not render dynamic data-command keyboard labels. All 28 inventories and
completed/source hashes reconcile: 19,160 unmarked messages, 9,644 changed help lines and 14 verified baseline
pairs. Report regenerated; git diff --check passes. No tests run. Previous checkpoint: `27d00888`.

Fresh fetch found all six source tips unchanged. origin/master remains `5c645187` with only the previously
inspected README/Linux test/CI changes left unmerged; guide hash unchanged. No new languages or relevant source
changes. All 270 since-start entries and 117 help passages match the pending inventory; no reopened-pair omissions.

### Croatian settings help completed

Reviewed download-ahead, brand-logos, pictures-tracking, sign-in-codes, new-mail, options-language and
default-mail-program. Improved Croatian control-label joins, download-label punctuation and unambiguous send-delay
wording. Clarified conditional background downloads, local-cache eviction, persistent logo reuse and domain
verification versus personal identity. Codes appear in large type, not necessarily uppercase. Watched-conversation
alerts obey notification settings and foreground suppression and only extend to ordinary user folders.

Windows Cancel discards unapplied local changes but cannot undo default-app choices in Windows Settings. Apply
may offer a language restart; Mac/Linux changes apply immediately except language. Both image topics explain
explicit permission for encrypted parts, even with a trusted sender or automatic loading enabled. All 27 catalog
targets and 11 help targets are now reviewed; closed Croatian's three settings-context followups. Other Croatian
help remains pending. No English or app-code changes.

Static checks report only 1,366 deliberately removed marks, no structural findings; all 46 shortcut scopes pass.
Exact tags, attributes, platform branches and literal keys are preserved. Inspected substituted controls, settings
paths and topic-title joins; dynamic keyboard labels are outside the preview helper. All 28 inventories and
completed/source hashes reconcile: 19,160 unmarked messages, 9,725 changed help lines and 14 verified baseline
pairs. Report regenerated; git diff --check passes. No tests run. Previous checkpoint: `0190587f`.

Fresh fetch confirms unchanged six source tips and guide. No new languages or relevant source changes; the same
unrelated README/Linux test/CI updates remain unmerged. All 270 since-start entries and 110 passages match pending
inventory, with no reopened-pair omissions.

### Croatian account, privacy and transfer help completed

Reviewed account-security, connections, links-scripts, data-storage, move-computer, manage-accounts,
sign-in-apps and unsubscribe. Improved formal Croatian instructions and rendered control joins. Passwords and
browser credentials are both covered in storage, removal and transfer guidance. An unprotected transfer requires
password or browser sign-in again; a new contact key waits for selection in the contact's properties.

Corrected automatic-image and persistent-logo conditions, external attachment opening, mail-link handling and
domain-versus-person trust. Account help distinguishes properties access with one account and marking all messages
in its folders read. OpenID Connect must also be supported by the mail servers; client secrets are hidden in the
editor after saving. Direct unsubscribe requires the confirmed signature to cover its headers and reports request
acceptance without promising that future mail will stop. All literal paths, examples and keyboard names remain intact.

Static checks report only 1,374 deliberately removed marks, no structural findings; all 46 shortcut scopes pass.
Exact tags, attributes, platform branches and literal code/keys are preserved. Substituted control/topic joins
inspected on all platforms; the preview helper does not render dynamic keyboard labels. All 28 inventories and
completed/source hashes reconcile: 19,160 unmarked messages, 9,823 changed help lines and 14 verified baseline
pairs. Report regenerated; git diff --check passes. No tests run. Previous checkpoint: `203dd91c`.

All six source refs and the guide remain unchanged since this turn's fresh fetch. The root checkout has no
uncommitted locale/help/settings changes. No new relevant work; the same unrelated upstream changes remain
unmerged. All 270 since-start entries and 110 passages match pending inventory. Full inventories also account
for the eight just-reviewed original draft topics, which were absent from the since-start report.

### Croatian encryption, contacts and agent help completed

Reviewed encrypted-and-signed-mail, encryption-keys, verify-a-key, address-book, invitations, agents-connect,
agents-permissions and agents-sending. Improved natural Croatian instructions and control-label joins. Corrected
cryptographic fingerprint terminology, valid signatures versus confirmed key ownership, checking every address,
private-key backups versus the system protection key, contact replacement keys, and calendar time-zone behavior.
Agent help describes scoped access, the 30-second minimum send delay, queue cancellation versus recalling mail,
and removal of saved access rather than uninstalling the agent program. The Claude Desktop configuration path
and restart step were checked against the [official MCP guide](https://modelcontextprotocol.io/docs/develop/connect-local-servers).

### Croatian troubleshooting and focused provider corrections completed

Reviewed certificate-errors, delivery-problems, encryption-errors, message-not-shown, no-connection and
password-not-accepted. Matched the actual Croatian errors and control labels; kept raw English low-level errors
recognizable. Removed false assurances about password validity, delivery and whether other apps can read a damaged
message. Connection advice now uses provider-supported security modes and ports. Bounce explanations distinguish
delayed delivery and local analysis from successful delivery.

The troubleshooting topic still offered app passwords for Outlook.com after the earlier account-setup corrections.
Reopened its second and third steps in 17 previously reviewed languages and completed those focused corrections;
all other text is unchanged. Four round-1 topics enter the scope; 13 previously counted topics were reopened without
double counting. Croatian received a full review. The ten broader drafts retain the followup. Guidance agrees with
the app's Microsoft warning, [Outlook.com's authentication requirements](https://support.microsoft.com/en-gb/outlook/pop-imap-and-smtp-settings-for-outlook-com)
and [Google's app-password eligibility rules](https://support.google.com/accounts/answer/185833). No English or app code changed.

All 18 affected language checks have only expected removed-mark diagnostics: 1,388 in Croatian, 1,395 in each other
language. No structural findings; all 46 existing mnemonic scopes pass. Exact tags, attributes, platform branches
and literal code/keys are preserved. Substituted control/topic joins inspected on all three platforms; dynamic
keyboard labels are outside the preview helper. All 28 current inventories and completed/source hashes reconcile:
19,160 unmarked messages, 10,007 changed help lines and 14 verified baseline pairs. Report regenerated;
git diff --check passes. No tests run. Previous checkpoint: `33e3e583`.

### New upstream encryption work discovered at this checkpoint

Fresh fetch found origin/master at `08c9ef12`, merging encrypted-message search/list support and Reading > Encryption
settings. Inventoried nine new catalog IDs and one changed ID in every language: 252 new and 28 changed entries.
Four help topics change in every language: encrypted-and-signed-mail, encryption-keys, options-language and
search-words, for 112 affected topics. There are no new languages. The other five recorded refs and guide hash are
unchanged, and the root checkout has no uncommitted locale/help/settings edits.

This upstream batch is recorded, not yet integrated. Commit this validated help checkpoint first, then integrate
the feature and reopen affected translations while preserving prior reviews. The preceding checks cover the current
checkout only. Its 270 since-start entries and 110 help passages match the queue; full inventories also cover the
original drafts omitted by that comparison. The final late-arrival audit remains required.

### Encryption/search feature integrated; affected translations reopened

Merged the feature tip `38841d96` directly, retaining its ancestry and leaving the five unrelated upstream
README/Linux test/CI paths outside this branch. Resolved 99 translation/help conflicts. Every unaffected catalog
value and comment and all previous help prose remain intact, including prior English-source corrections.
New drafts were inserted into the current text. Seventy-one previously reviewed help topics mark only their
new passages; the remaining affected topics were already pending full review.

Added 252 new catalog IDs and reopened 18 changed entries, including four round-1 entries entering this scope.
Four help topics per language are affected; twelve round-1 topics enter the scope. Prior review history is
preserved under reopened fields and retained-prose hashes. No imported draft is counted reviewed. Current
completed counts fall because affected entries/topics are pending again, not because earlier edits were lost.

All 28 language inventories, full variable sets, access-key counts, help references and exact pending marks pass.
Static language checks report only 25,185 expected removed/partial-mark diagnostics. All 46 mnemonic scopes pass
in the 18 previously reviewed app languages, and all three settings-page scopes pass in every language. The ten
broader drafts' shortcut collisions are byte-for-byte the same lists as before integration; Romanian Gri also
still lacks a free runtime flag mnemonic. These remain recorded for their initial reviews.

All 76 implementation/generated imports match the feature source. Global reconciliation accounts for 19,146
unmarked messages, 10,007 changed help lines and 14 verified baseline pairs. All completed/source hashes match.
The 550 since-start entries and 265 passages match the queue. Review HTML regenerated; locale/help/record
diff checks pass. The full staged check passes with cr-at-eol for the imported email fixture’s intentional CRLF
endings; its bytes match upstream exactly.
No tests or builds run; installer/store metadata was not changed. The source refs remain as freshly fetched;
no new languages were found. Review the German encryption additions next, followed by Spanish/Estonian/French.

### German encryption additions completed

Reviewed ten catalog targets and seven added passages across four help topics. Improved three catalog values
and six help passages, leaving the search-filter row unchanged after review. Every byte outside the inserted
help passages is preserved. Settings explain the need for available keys, the unencrypted local search index
and logical removal of decrypted indexed content when disabled. Key lookup distinguishes an email address from
a fingerprint/key ID and keeps domain lookup available when the keyserver is disabled.

The source's notification wording needed correction: new encrypted-mail notifications always use the encrypted-
message label, while the list may later show a decrypted preview and protected subject. Agent help describes
blocked encrypted contents and attachments without implying that outer envelope metadata is hidden. Recorded
these context decisions for the remaining languages. No English/app code changed in this review batch.

German static checks report only 1,404 expected removed-mark diagnostics; all 46 shortcut scopes pass. Exact
variables, comments, markup, literal tokens and pending inventories are preserved. Control/settings/topic joins
checked on all platforms; dynamic keyboard labels are outside the preview helper. Global reconciliation accounts
for 19,156 messages, 10,014 changed help lines and 14 verified baseline pairs. Current completed/source hashes
match. HTML report regenerated; git diff --check passes. No tests run. Previous checkpoint: `c83a2e31`.

Fresh fetch confirms unchanged six source refs and guide, with no uncommitted locale/help/settings changes in root.
Only the five known unrelated upstream paths remain unmerged. All 540 since-start entries and 258 passages match
the pending queue. No further language or translation additions were found. Spanish is next.

### Spanish, Estonian and French encryption additions completed

Reviewed 30 catalog targets and 21 inserted passages across 12 help topics, improving 14 catalog values
(Spanish three, Estonian eight, French three) and 19 help passages. The Spanish/French search-filter rows were
already natural; Estonian now uses the established krüpteerima terminology throughout the additions. Existing
polite forms, huella digital / võtme sõrmejälg / empreinte and attachment terms remain consistent.

Replaced literal own-subject/words phrasing with natural explanations of searchable contents and message previews.
Available keys qualify decryption, and settings describe unencrypted local indexing and removal when disabled.
New-mail notifications retain the encrypted-message indication independently of the list preview. Agent limits
refer to encrypted contents and attachments, without hiding the distinction from outer envelope metadata. Key
lookup separates address/domain queries from fingerprint/key-ID queries; disabling keyserver lookup leaves
lookup in the address domain available. Every byte outside the marked help passages is preserved.

Each language has only 1,404 expected removed-mark diagnostics and passes all 46 shortcut scopes. Exact variables,
comments, tags, attributes and literal search syntax are preserved. Substituted control/settings/topic joins were
checked on all platforms; dynamic keyboard labels remain outside the preview helper. All 28 inventories and current
file/source hashes reconcile: 19,186 unmarked messages, 10,035 changed help lines and 14 verified baseline pairs.
HTML regenerated; git diff --check passes. No tests run. Previous checkpoint: `d74973e3`.

All six source refs and the guide match after this turn’s fresh fetch; root has no uncommitted locale/help/settings
edits. Only the five known unrelated upstream paths remain unmerged. The 510 since-start entries and 237 passages
match the queue; no additional relevant work was found. Dutch is next, then Italian and both Portuguese variants.

### Dutch, Italian and both Portuguese encryption additions completed

Reviewed 40 catalog targets and 28 inserted passages across 16 help topics, improving 13 catalog values
(three each in nl/it/pt, four in pt-BR) and 24 help passages. The four search-filter rows were already natural.
Dutch keeps informal je and Italian tu. Portuguese distinguishes European encriptação/transferir/utilizador/
pré-visualização from Brazilian criptografia/baixar/usuário/prévia and uses the appropriate forms of address.
Control labels and access keys were suitable and remain unchanged.

The settings explain private-key availability, local unencrypted search content and removal from the index when
disabled. List previews and protected subjects are distinguished from notifications, which always use the
encrypted-message indication. Agent limits apply to protected contents and attachments, with no claim that envelope
metadata is hidden. Address/domain queries and fingerprint/key-ID queries are explained separately. Every byte
outside the seven inserted help passages per language is unchanged.

All four languages pass 46 shortcut scopes and have only 1,404 expected removed-mark diagnostics each. Exact IDs,
variables, comments, tags, attributes, literal search syntax and all 28 pending inventories match. Substituted
control/settings/topic joins were inspected for Windows, Mac and Linux; dynamic keyboard labels are outside the
preview helper. Global reconciliation covers 19,226 unmarked messages, 10,063 changed help lines and 14 verified
baseline pairs. Current translation/source hashes match. HTML regenerated; git diff --check passes. No tests or
builds run. Previous checkpoint: `abc89754`.

Fresh fetch found all six recorded refs and the guide unchanged; root has no locale/help/settings edits. Only the
five known unrelated upstream paths remain unmerged. All 470 since-start entries and 209 passages match the queue;
no new languages or unrecorded work were found. Catalan is next, followed by Norwegian Bokmål, Serbian Latin and
Turkish, then the remaining focused encryption batches and broader reviews.

### Catalan, Norwegian Bokmål, Serbian Latin and Turkish encryption additions completed

Reviewed 40 catalog targets and 28 inserted passages across 16 help topics, improving 15 catalog values
(Catalan three, Norwegian three, Serbian four, Turkish five) and 24 help passages. The four search-filter rows
were already natural. Catalan retains vós prose and vista prèvia; Norwegian uses du, KI-agent and fingeravtrykk;
Serbian retains Ekavian, formal plural, otisak ključa and prilog; Turkish uses polite prose, gizli anahtar and
etki alanı. The Turkish keyserver label is shorter and more idiomatic, with its n access key retained.

Clarified available private keys, unencrypted local search content, removal from the index when disabled,
conditional list previews and unconditional encrypted-mail notification text. Agent restrictions apply to
protected contents and attachments; address/domain lookup differs from fingerprint/key-ID lookup. The Serbian
settings error has a head noun for the uninflected path. Substituted Catalan labels revealed de Eines/de Inbox
Classic, fixed with a relative clause that works on all three platforms. All text outside the inserted help
passages remains byte-for-byte unchanged.

Each language passes 46 shortcut scopes and has only 1,404 expected removed-mark diagnostics. Exact IDs, variables,
comments, tags, attributes, literal syntax and all 28 pending inventories match. Control/settings/topic joins were
inspected for Windows, Mac and Linux; dynamic keyboard labels are outside the preview helper. Global reconciliation
covers 19,266 unmarked messages, 10,091 changed help lines and 14 verified baseline pairs. Current translation/source
hashes match. HTML regenerated; git diff --check passes. No tests or builds run. Previous checkpoint: `2c317eb3`.

Fresh fetch found all six recorded refs and the guide unchanged; root has no locale/help/settings edits. Only the
five known unrelated upstream paths remain unmerged. All 430 since-start entries and 181 passages match the queue;
no new languages or unrecorded work were found. Bulgarian is next, then Czech, Danish, Greek, Finnish and Croatian.

### Bulgarian, Czech, Danish, Greek and Finnish encryption additions completed

Reviewed 50 catalog targets and 35 inserted passages across 20 help topics, improving 19 catalog values
(Bulgarian three, Czech six, Danish three, Greek four, Finnish three) and 30 help passages. The five search-filter
rows were already natural. Czech row labels now agree with zpráva, matching the neighboring unread label. Czech
and Greek settings paths use head nouns without inflecting inserted labels. Finnish now describes purkaa viestin
salauksen rather than unpacking the message; hakuindeksi replaces the literal hakuhakemisto. These Finnish
terminology decisions are recorded in the glossary. Existing forms of address and access keys are preserved.

The additions distinguish available private keys, unencrypted local search content, removal from the index when
disabled, conditional list previews and unconditional encrypted-mail notification text. Agents cannot access
protected contents or attachments; domain/address lookup differs from fingerprint/key-ID lookup. Every byte
outside the newly inserted help passages is unchanged.

All five languages pass 46 shortcut collision scopes and have only 1,404 expected removed-mark diagnostics each.
Exact IDs, variables, comments, tags, attributes, literal syntax and all 28 pending inventories match. Substituted
control/settings/topic joins were inspected on Windows, Mac and Linux; dynamic keyboard labels remain outside
the helper. The existing Greek runtime-generated accented flag mnemonic remains documented as an app-side issue.
Global reconciliation covers 19,316 unmarked messages, 10,126 changed help lines and 14 verified baseline pairs.
Current translation/source hashes match. HTML regenerated; git diff --check passes. No tests or builds run.
Previous checkpoint: `d3512067`.

Fresh fetch found all six recorded refs and the guide unchanged; root has no locale/help/settings edits. Only the
five known unrelated upstream paths remain unmerged. All 380 since-start entries and 146 passages match the queue;
no new languages or unrecorded work were found. Croatian is next. Its search-words remains a full original topic,
so review the entire topic along with the inserted encryption passages in the other three affected topics. Then
finish all-inboxes, command-line, keyboard-shortcuts, removing, save-print-import and updates.

### Croatian review completed; shared search-negation wording corrected

Reviewed Croatian's ten encryption/search catalog targets and all ten remaining help topics: seven original
full topics plus five inserted passages in three previously reviewed topics. Improved four catalog values and
68 help lines, excluding mark removal. Croatian now has no pending catalog entries or help topics.

The new encryption prose describes available keys, unencrypted local indexing, index cleanup, conditional list
previews, unconditional notification labels, protected contents unavailable to agents and address versus key-ID
lookup. Original help now uses expanded/collapsed combined views, actual account selection, URL output for the
sign-in-page option, broad sign-in credentials, Croatian Alt+K/Alt+S beside the original Cc/Bcc keyboard tags,
and address selection rather than “taking a person”. Removing suggestions leaves saved contacts/groups intact.
Uninstall instructions distinguish local data from server mail. Multi-message export avoids overwriting existing
files; Mac update checks are enabled by default and configurable. Localized Windows/Mac/Linux joins were inspected.

Search examples and all literal command/keyboard tokens are preserved. The search page describes supported
Gmail-style syntax, common recipient aliases, inclusive after dates and actual Croatian diacritic behavior:
č/ć/š/ž match their unaccented forms, while đ and d differ. Verified this with an isolated in-memory SQLite query
using the app's configured tokenizer, without running any project test suite.

Code review also exposed a source-help overclaim: minus does not negate date, age or size filters. Corrected that
one table sentence in the 17 previously completed languages, retaining every other byte. Croatian received the
correction during its full review. `search-negation-context` records the evidence and the ten broader drafts still
to process. This adds no new scope or pending topics because those drafts already have search-words marked.

Croatian passes all 46 shortcut collision scopes. It and the 17 search-only followups have exactly 1,404 expected
removed-mark diagnostics each and no structural findings. All help tags, attributes and literal tokens match.
The preview helper substitutes control/settings/topic labels; dynamic command-key labels and generated shortcut
tables are outside that preview. All 28 inventories and current file/source hashes reconcile, covering 19,326
unmarked messages, 10,258 changed help lines and 14 verified baseline pairs. HTML regenerated; git diff --check
passes. No test suites or builds run. Previous checkpoint: `b0bdea4a`.

Fresh fetch found the same six source refs and guide, no root locale/help/settings edits and no new languages.
Only five known unrelated upstream paths remain unmerged. The 370 since-start entries and 140 passages match
the pending queue. Hungarian is next, beginning with its 647 pending app.ftl entries.

### Hungarian app catalog completed; Undo Send status corrected

Reviewed all 647 Hungarian app entries against menus, dialogs and callers. Improved 83 values: 66 wording
changes and 18 shortcut placements, with one overlap. All 46 actual menu/dialog/settings shortcut scopes pass.
Rules now process messages rather than change their sort order. The local mail store is levéladatbázis;
sign-in credentials are bejelentkezési adatok, including browser sign-in. Key guidance distinguishes digital
signatures, ownership and message-signature text, with uninflected names/addresses/fingerprints and independent
count agreement. Provider text limits app passwords to supported accounts and directs Microsoft users to
browser sign-in. Settings transfer no longer promises a password prompt for every account.

Encrypted-search guidance covers available keys, locally stored unencrypted content, index cleanup and agent
restrictions. Key lookup distinguishes addresses from key IDs. Sender pictures refer to the column layout,
domain authentication and cache reuse. Formal Hungarian phrasing, singular nouns after numbers and existing
good wording are preserved. Glossary decisions are recorded for the remaining catalogs/help. No Hungarian
tour screenshots were available; longer notes were checked against source wrapping, without a GUI run.

The Undo Send caller exposed another English overclaim: expiry of the delay makes take_back refuse even if
sending has not completed. Changed that status to say sending can no longer be undone in Hungarian and the
18 earlier reviewed languages. Each earlier-language file has exactly one changed value and otherwise identical
bytes. The four round-1 entries add four to scope; the other 14 are followups without added scope. The remaining
nine drafts retain this entry in their existing queue under undo-send-deadline-context. English/app code unchanged.

Hungarian check-language reports exactly 657 expected removed-mark diagnostics; each of the 18 followups has
1,404. No structural findings. All 28 inventories and completed/source hashes reconcile: 19,977 unmarked
messages, 10,258 changed help lines and 14 verified baseline pairs. The 339 since-start entries and 140 help
passages match the integrated queue. HTML regenerated; git diff --check passes. No test suites or builds run.
Previous checkpoint: `71df1f4b`.

The six tracked source refs and guide are unchanged after a fresh fetch. A wider local-branch check found NEW
help additions on `chore/pgp-hardening`, observed at `80d02fcc`; help commit `255205aa` inserts one passage in
connections, data-storage and encryption-keys for all 28 languages and English. Exact source text/hashes are
saved in state. These additions are not yet integrated or counted below. Integrate them next without replacing
reviewed paragraphs. The source worktree has unrelated uncommitted UI/fuzz changes that must be preserved.
Its connections paragraph also overclaims address-only lookup during encryption: retain the already verified
manual lookup/key-ID context. Receiving an Autocrypt key does not establish ownership, and sending it is optional.

### New key help source integrated; linguistic review pending

Imported help-only commit `255205aa` from `chore/pgp-hardening`, observed at `80d02fcc`, after review checkpoint
`e33a6887`. It adds one passage to connections, data-storage and encryption-keys in each of 28 languages and
English. Resolved 39 overlaps by reconstructing the reviewed parent plus the exact source insertion. Every
prior byte is retained. English exactly matches the source commit; no editorial English/app changes made.
Other code/docs/tests on that branch and its uncommitted UI/fuzz work are untouched.

The 18 earlier languages have only the inserted passages marked. Ten broad drafts retain whole-topic marks.
Four round-1 data-storage topics enter the active scope; 50 counted topics reopen and 30 full topics were already
pending. Archived older partial-review provenance where a newer completed checkpoint supersedes it. No new
passage has been marked linguistically reviewed by this integration.

Actual callers confirm key lookup also happens on explicit requests, not only while encrypting. Address queries
try the domain before the enabled keyserver fallback; fingerprint/key-ID queries send that identifier. Private
keys are encrypted in the mail database with a separate key in the credential store. Autocrypt shares public
keys when enabled and learns usable sender keys when messages are opened; receipt does not verify ownership.
Apply these points while replacing the literal draft wording. Start with de/es/et/fr, then the other 14 earlier
languages; the ten broad drafts get these passages during their full-topic review.

All 28 structural checkers report only expected removed-mark diagnostics. All full catalogs/variables/help
inventories and pending marks match; current completed/source hashes reconcile. Global counts remain 19,977
unmarked messages, 10,258 changed help lines and 14 verified baseline pairs, since all additions are marked.
The 339 since-start entries and 214 passages match the queue. Fixed the temporary audit helper to trim each
help line as the report does, allowing newly changed whole topics to match their 160-character previews.
HTML regenerated; git diff --check passes; no conflict markers. No test suites or builds run.

### German, Spanish, Estonian and French key help additions reviewed

Reviewed the twelve inserted passages in connections, data-storage and encryption-keys, improving all twelve.
Every byte outside those passages is unchanged. Key lookup now includes explicit requests and distinguishes
address queries from fingerprint/key-ID queries. Storage prose explains encrypted private keys and the separate
protecting key held with sign-in credentials. Autocrypt descriptions explain optional public-key sharing and
receiving usable sender keys on message opening, without claiming verified ownership. Estonian retains polite
plural address; the new informal draft wording and literal “keys travel”/“app learns” phrases are removed.

All four check-language runs have exactly 1,404 expected removed-mark diagnostics and no structural findings.
Tags, attributes, literal code/keyboard tokens and platform branches are intact. Autocrypt/Security label joins
were inspected for Windows, Mac and Linux; dynamic keyboard labels remain outside the helper. All 28 full
inventories and current translation/source hashes reconcile: 19,977 unmarked messages, 10,270 changed help lines
and 14 verified baseline pairs. HTML regenerated; git diff --check passes. No test suites or builds run.
Previous/source integration checkpoint: `7491abc8`.

All seven observed source refs and the guide remain unchanged; root has no relevant edits. The 339 since-start
entries and 202 passages match the queue. The help-only import leaves non-help changes and the active source
worktree untouched. Next: nl/it/pt/pt-BR, then the other ten earlier languages listed in Resume here.

At that checkpoint: 19,943 catalog entries and 758 help topics fully completed; 3,357 historical catalog improvements.
Remaining: 12,773 catalog entries and 562 help topics. Of those help topics, 42 need only their new insertion;
520 belong to the ten broader language drafts. Scope: 32,716 entries and 1,320 topics. `REVIEWED` unchanged.

Context to retain: the new languages were drafted before the last source corrections. Check the round-1 final
consistency findings when reviewing their encryption, transfer, attachment and folder-navigation text.

Additional context for later languages: a TLS-required server response does not prove the password valid;
a malformed message is unreadable by this app, not necessarily every mail app. Attachment opening uses an
external handler after saving a temporary copy. The sign-in-page-file switch writes a URL, not page HTML.


### Remaining key help additions reviewed in all earlier languages

Reviewed and improved all 42 inserted passages in Dutch, Italian, European and Brazilian Portuguese, Catalan,
Norwegian Bokmål, Serbian Latin, Turkish, Bulgarian, Czech, Danish, Greek, Finnish and Croatian. All 18 earlier
languages are caught up again. Every byte outside the new passages is preserved. The 30 insertions in the ten
broader drafts remain marked within their full topics and will be reviewed with those topics.

Key lookup includes explicit requests and distinguishes addresses from fingerprints or key IDs. Private keys
are encrypted in the local mail database with a separate protecting key held with sign-in credentials. Autocrypt
sharing depends on the sending address's assigned key and setting; receiving a sender's public key when opening
a message does not verify its owner. Each language retains its established register and technical terminology.
Replaced literal descriptions of keys travelling, learning a contact, and files opening keys with natural prose.

All 14 check-language runs report exactly 1,404 expected removed-mark diagnostics each and no structural findings.
Tags, attributes, literal code/keyboard tokens and platform branches are intact. Autocrypt/Security sentence joins
were inspected with the actual labels on Windows, Mac and Linux. Croatian quotes were aligned with the glossary
and its checks repeated. All 28 full inventories, pending marks and current translation/source hashes reconcile:
19,977 unmarked messages, 10,312 changed help lines and 14 verified baseline pairs. HTML regenerated;
git diff --check passes. No test suites or builds run. Previous checkpoint: `ed362530`.

Fresh fetch and all seven observed refs show no additional translation edits or languages. The guide is unchanged;
root has no relevant edits. The exact imported source for all 87 help files is still verified. Other source-branch
changes, including UI behavior and fuzz corpora, remain outside this review and untouched. The 339 since-start
entries and 160 passages match the queue. State records the audit with compact counts for the large corpus tree.

At that checkpoint: 19,943 catalog entries and 800 help topics fully completed; 3,357 historical catalog improvements.
Remaining: 12,773 catalog entries and 520 help topics in hu/lt/lv/pl/ro/ru/sk/sl/sv/uk. Scope: 32,716 entries and
1,320 topics. Next: Hungarian core.ftl (450 entries), then its remaining catalogs and all 52 help topics.
`REVIEWED` remains unchanged until the full queue and final late-arrival audit are complete.


### Hungarian core catalog completed; agent Undo status clarified

Reviewed all 450 remaining Hungarian core messages and improved 96 values. Reading errors, delivery-failure cards,
count messages, calendar text, sign-in, agent permissions and logs, keys, setup transfer and attachment handling
were checked against their actual callers. Hungarian keeps singular predicates after numbers and leaves dynamic
names, addresses, fingerprints and counted phrases uninflected. Good existing translations are retained.

Bounce advice distinguishes a server retry from a user action. Local storage uses levéladatbázis; credentials
include browser sign-in. Agent logs now report queuing, not completed sending. Security details correctly say
decrypted, distinguish key ownership from signature validity, and explain that every published address requires
confirmation. Locked private keys require their own backup. Setup errors refer to the exported file; an unreachable
sign-in-app message works whether it names the app or an account. Temporary unencrypted attachment copies older
than a day are removed at startup. Hungarian glossary notes record these decisions for its remaining help review.

The agent Undo caller exposed another source overclaim: agent-undo-sent is used whenever the Outbox row is missing,
which also happens after deleting a queued message without sending it. Corrected this one reason in Hungarian and
all 18 earlier languages to say the message is no longer in the Outbox. Every other byte in those 18 files is
unchanged. Four round-1 entries enter scope; the other 14 are followups without increased scope. The nine remaining
drafts retain the entry under agent-undo-outbox-context. English and app code are unchanged.

Hungarian check-language reports 1,107 expected removed-mark diagnostics; each of the 18 followups has 1,404.
There are no structural findings. All 96 Hungarian value edits and 450 mark removals reconstruct the exact file
from the prior checkpoint. IDs, full variables, plural branches, braces, mnemonics and comments are preserved.
Error-wrapper joins were inspected in all 19 languages, with independent-clause capitalization fixed in German.
Hungarian substituted examples include failure counts, credential-store names and account/app identifiers.
No GUI run or Hungarian tour screenshots were available; source wrapping and compact permission controls were checked.

All 28 inventories and current translation/source hashes reconcile: 20,431 unmarked messages, 10,312 changed help
lines and 14 verified baseline pairs. The 336 since-start entries and 160 passages match the queue. Fresh fetch
and all seven observed refs show no new translations or languages; guide unchanged and root has no relevant edits.
HTML regenerated; git diff --check passes. No test suites or builds run. Previous checkpoint: `6e24497c`.

Current totals: 20,397 catalog entries and 800 help topics completed; 3,471 historical catalog improvements.
Remaining: 12,323 catalog entries and 520 help topics across ten languages. Scope: 32,720 entries and 1,320 topics.
Next: Hungarian help.ftl (24), linux.ftl (87), mac.ftl (65), windows.ftl (69), then all 52 help topics.
All 18 earlier languages are caught up. `REVIEWED` remains unchanged; the final late-arrival audit is still required.


### Hungarian platform catalogs and getting-started help reviewed

Reviewed the remaining 245 Hungarian catalog entries: 24 help titles, 87 Linux, 65 Mac and 69 Windows entries.
Improved 45 values, keeping good existing labels and native Mac menu conventions. Corrected search scope and
independent failure counts, clarified agent removal and unused access, and aligned Linux provider guidance with
the shared account dialog. Installer wording distinguishes a Windows user from a mail account; the store text
names the message list, downloaded offline mail and hidden quoted text. Sign-in button images are unchanged.

Reviewed add-account, gmail-outlook, main-window and layouts. Control labels now join natural Hungarian sentences,
with a/az chosen from the actual labels and case endings on surrounding nouns. Adding an account is distinct from
creating one. Provider help limits app passwords to eligible Google accounts with two-step verification and directs
Microsoft mail to browser sign-in. This completes the Hungarian provider-app-password followup; its separate
password-troubleshooting followup remains pending. The main-window topic describes combined Sent/Drafts views
and collapsed-folder counts, excluding Junk/Deleted. Layout text describes three-line list entries and locally available preview text.

Structural checks have exactly 1,356 expected removed-mark diagnostics and no other findings. All 46 mnemonic scopes
passed; exact reconstruction verifies the 45 catalog edits and 245 mark removals. Help tags, attributes, literal keys,
control references and platform branches are preserved. Control/settings-path joins were inspected on all platforms;
dynamic shortcut references were checked in commands.toml. The separate-target offline pe-ffi build passed in 10.14s.
Only four Hungarian installer values and five Hungarian store elements changed; generated text matches its catalogs.
No test suite was run. All 28 active inventories and current hashes reconcile: 20,676 unmarked messages, 10,371 changed
help lines and 14 verified baseline pairs. The 333 since-start entries and 159 passages match the active queue.
HTML regenerated; git diff --check passes. Previous checkpoint: `f90cee0e`.

Fresh source discovery found compose signing/encryption merged into origin/master at `a6ed91d6`. Across all 28 languages,
it adds 1,120 catalog entries, 28 new sign-and-encrypt topics and 28 write-message insertions. No new languages appeared.
Eighteen previously completed topics will reopen only for their new insertion. The guide and root translation files
are unchanged. The hardening branch also advanced to `9b6dea1b`; its identical compose sources are deduplicated, and
its earlier 87-file key-help import remains verified. Non-help source changes and other worktrees are untouched.
Exact pending source IDs/files/hashes are recorded separately; integrate after this clean Hungarian checkpoint and
then update scope before reviewing them. The new work is not included in the current-checkout totals below.

Current checkout: 20,642 catalog entries and 804 help topics completed; 3,516 historical catalog improvements.
Remaining here: 12,078 catalog entries and 516 help topics. Scope: 32,720 entries and 1,320 topics. Hungarian has
48 help topics left. The next batch is the compose source integration and followup review, then Hungarian help.
`REVIEWED` remains unchanged; the full queue and final late-arrival audit are still required.


### Compose signing/encryption source integrated; review pending

Merged feature `162c0dd2` (observed in origin/master merge `a6ed91d6`) after Hungarian checkpoint `040b7373`.
Resolved 52 catalog/help overlaps using the prepared parent-plus-insertions result. All earlier catalog bytes,
comments and help prose remain intact, including five prior English source corrections. All 116 catalog/help
outputs match that prepared result; the 76 imported implementation/generated paths and topics metadata match
upstream. Existing key-help additions and unrelated worktrees remain untouched.

The import adds 40 IDs per language and a new sign-and-encrypt topic, plus one paragraph in write-message.
Previously reviewed write-message topics mark only the insertion. Four round-1 topics enter scope and fourteen
already counted topics reopen; ten original drafts were already pending. New scope is 33,840 entries and 1,352
help topics; pending is 13,198 entries and 562 topics. Completed: 20,642 entries and 790 full topics. This is
source integration only: no new draft was counted linguistically reviewed.

All 28 catalog/variable/access-key inventories, help references and pending marks pass. Structural checkers
report exactly 26,718 expected removed/partial-mark diagnostics and no other findings. Global reconciliation
accounts for 20,676 unmarked messages, 10,371 changed help lines and 14 verified baseline pairs. Current hashes
match. The 1,453 since-start catalog entries and 215 passages match the queue. Both staged and unstaged
whitespace checks pass. Expanded the actual-menu helper from 46 to 53 scopes. New collisions in bg/cs/lt/pl/sk/sl/uk/ca/tr are
recorded for review, along with the prior broader-draft issues. HTML regenerated; no tests or builds run.

Actual behavior requires context corrections during review: compose status describes intended protection;
valid signatures do not prove key ownership. Recipients need usable keys, and missing-key counts include
unusable ones. Verified recipients use green locks; the separate overall status bar uses a shield. Lookup and warning
icons vary by platform. This corrects the initial integration note after inspecting each individual icon caller. Unencrypted sending stays blocked while protected quoted text, inline media or extracted attachments
remain. Encrypted drafts use the sender's key only and are not signed; sent copies retain encryption.
Remove from Message removes recipient fields, not contacts. All details and source callers are in state.
Review German next, followed by Spanish, Estonian and French, then the other earlier languages and Hungarian.


### German compose additions reviewed; another late source reason found

Reviewed all 17 new app labels and 23 core messages, retaining good labels and improving 16 core values.
Status text describes protection applied when sending. Signatures support integrity checks without claiming
verified ownership. Missing-key guidance includes unusable keys; placeholders work for names/address lists,
counts and full-sentence key-state reasons. Downgrade warnings cover inherited text, images and attachments,
and unencrypted sending is conditional. Reviewed the new sign-and-encrypt topic and only the inserted paragraph
in write-message, improving 14 help lines. Every earlier write-message byte is preserved.

Help uses a cross-platform color/status table instead of calling every icon a lock. Green means verified key
ownership; blue also covers own keys, and orange includes unusable keys. The integration note was corrected:
individual recipients use locks, while the separate overall status bar can use a shield. Encrypted drafts use
the sender's own key; attaching a public key follows the selected From address. German glossary notes record
signature terminology, usable-key conditions and whole-sentence reason handling.

All 53 mnemonic scopes pass. The structural checker has exactly 1,445 expected removed-mark diagnostics and no
other findings. Exact reconstruction verifies the 16 value edits and 40 mark removals; variables, plural branches,
comments, help tags/attributes/keys and platform branches are preserved. Control joins were inspected on all
three platforms. An existing German Linux compose screenshot was inspected, but it predates the new controls;
new layout/wrapping was checked in source. No GUI run, test suites or builds.

All 28 active inventories and current hashes reconcile: 20,716 unmarked messages, 10,391 changed help lines and
14 verified baseline pairs. The 1,413 since-start entries and 213 passages match the queue. HTML regenerated;
git diff --check passes. Current totals: 20,682 entries and 792 topics reviewed, 13,158 entries and 560 topics
pending; 3,532 historical catalog improvements. Scope remains 33,840/1,352 before the next source integration.

Fresh fetch and source comparison found one more reason in all 28 languages: pgp-why-not-key-in-use, from
`9924cfe7` on the hardening branch, now at `c69576e6`. It reports a signing key different from the key currently
selected for the From address. It does not mean an expired key, an invalid cryptographic signature or proven
impersonation. No other source values or languages changed. Exact hashes and caller evidence are recorded for
focused integration next; these 28 additions are not yet counted in the active inventory. The guide and root
translation files are unchanged. Other source-branch changes remain untouched. `REVIEWED` is unchanged.


### Active-key signature reason imported for review

Inserted the exact new pgp-why-not-key-in-use source entry into English and all 28 translations, preserving every
prior catalog byte. Source commit9924cfe7 depends on a broader refactor of the signature reader, so this import
contains catalogs and regenerated text identifiers only. Its caller, active correspondent/identity key mapping
and warning presentation were inspected in the source branch. No hardening code or corpus files were imported.

The separate-target offline pe-ffi build passed in 12.05s. The two generated text identifier files match the focused
source exactly; installer/store outputs are unchanged. All 28 structural checkers report only the expected 26,759
removed/partial-mark diagnostics. Full catalogs, variables and pending inventories match. The new reasons remain
marked, with no linguistic review claimed yet. Scope33868/1352, pending13186/560, completed20682/792.
All20,716 unmarked messages and10,391 changed help lines reconcile, with14 verified baseline pairs; current hashes match.
HTML regenerated; git diff --check passes. No test suite was run. Next: review all28 reasons and their encrypted-message wrapper, then Spanish compose.


### Signature-key warning reviewed in all 28 languages

Reviewed pgp-why-not-key-in-use standalone and inside each encrypted-part label. Improved 13 drafts, retaining
15 already natural translations. Removed Hungarian a(z), corrected Finnish's incomplete comparison, made key/address
relationships clearer, and kept Catalan typography. Swedish now uses neuter Signerat with meddelande; its existing
Krypterad wrapper was also reviewed and corrected to Krypterat. Other pending Swedish messages remain marked.
The warning describes a different active key, without claiming expired keys, failed cryptography or proven fraud.
All placeholder addresses remain uninflected; register and terminology match the language notes.

All 28 structural checkers report only expected removed/partial-mark diagnostics (26,788 total). Exact reconstruction
verifies 29 reviewed entries and 14 value improvements with every other byte preserved. Representative address joins
were inspected in all 28 languages. Full inventories and hashes reconcile: 20,745 unmarked messages, 10,391 changed
help lines and 14 verified baseline pairs. HTML regenerated; git diff --check passes. No test suites run. The earlier
12.05s source-import build was not repeated for these single-line wording edits.

All seven source refs remain unchanged; no further strings or languages were found. The guide is unchanged, root has
no relevant edits, and the existing key-help source and active-key entry remain verified. Dependent hardening code
and corpus work remain separate. Current scope33868/1352; completed20711/792; pending13157/560. Historical catalog
improvements3546. Continue Spanish compose next, then Estonian and French. REVIEWED remains unchanged.


### Spanish compose signing and encryption reviewed

Reviewed all 17 new app labels and 23 core messages. Kept the good labels and improved 15 core values:
intended protection when sending, signature integrity without proof of authorship, usable-key requirements,
natural address/count/date joins and complete key-state reasons after «Motivo». Downgrade warnings cover quoted
text, images and attachments, and sending without encryption is conditional. Formal usted and existing terms
remain consistent; the glossary records the compose terminology and reason-placeholder decisions.

Reviewed the new sign-and-encrypt topic and only the marked write-message paragraph, improving 14 help lines.
The help distinguishes key ownership from signature checks, uses a cross-platform color/status table, includes
own keys in blue status and unusable keys in amber, and explains the selected From key, encrypted drafts and
recipient removal. All earlier write-message bytes remain intact. Control-label joins were inspected on all
three platforms and dynamic shortcuts checked in commands.toml. The existing Spanish compose screenshot was
inspected but predates the new controls; their layout/wrapping was checked in platform source. No GUI run.

All 53 actual mnemonic scopes pass. Spanish's structural checker reports exactly 1,446 expected removed-mark
diagnostics and no other findings. Exact reconstruction verifies 15 value edits and 40 mark removals; variables,
selectors, comments, help tags/attributes/control references/platform branches/literal keys are preserved.
All 28 full inventories and current hashes reconcile: 20,785 unmarked messages, 10,411 changed help lines and
14 verified baseline pairs. The 1,373 since-start entries and 211 passages match the remaining queue.
HTML regenerated; git diff --check passes. No test suites or builds run.

Fresh fetch and seven-ref audit found no source changes, new strings or new languages. Existing key-help and
active-key sources match recorded imports; guide unchanged and root has no relevant edits. Other hardening
code and corpus changes remain separate. Completed: 20,751 entries and 794 topics; pending: 13,117 entries
and 558 topics. Scope remains 33,868/1,352; historical catalog improvements: 3,561. Continue Estonian, then
French compose additions. REVIEWED is unchanged; the complete queue and final late-arrival audit remain.


### Estonian compose signing and encryption reviewed

Reviewed 40 additions, keeping all17 app labels and improving17 core values. Replaced informal sina with the
app's polite teie in explanations and questions, and replaced literal võtmele with natural key-use wording.
Status describes protection applied when sending; signatures establish integrity without proving ownership.
Missing-key guidance includes unusable keys. Reason placeholders follow Põhjus with the next instruction
separate. Downgrade warnings include inherited text, images and attachments, and unencrypted sending is conditional.

Reviewed the new help topic and write-message insertion, plus three older passages exposed by rendered joins:
address suggestions, account selection and plain-text sending. Those passages were explicitly reopened and
recorded with before/after text. All other earlier prose is retained. Help uses a cross-platform color/status
table, covers own keys and unusable keys, and explains the selected From key, recipient removal and encrypted
drafts/sent copies. Twenty help lines improved. Glossary notes record the deliberate wording decisions.

All53 mnemonic scopes pass. The structural checker reports only1446 expected removed-mark diagnostics.
Exact reconstruction verifies17 value changes and40 mark removals; all help tags/attributes/controls/platform
branches/literal keys are preserved. Joins inspected on all platforms; the old Estonian screenshot predates new
controls, so new wrapping/layouts were checked in source. No GUI run, test suites or builds.
All28 inventories/current hashes reconcile:20825 unmarked messages,10434 changed help lines and14 baseline pairs.
Since-start1333 entries/209 passages match the queue. HTML regenerated and git diff --check passes.

Fresh fetch/seven-ref audit found no new strings or languages; existing source imports and guide unchanged,
root has no relevant edits. Other hardening/corpus changes untouched. Completed20791 entries/796 topics;
pending13077/556; scope33868/1352; historical catalog improvements3578. French compose is next. REVIEWED unchanged.


### French compose signing and encryption reviewed

Reviewed all 40 additions, retaining the 17 app labels and improving 17 core values. Status now describes
protection applied à l’envoi; signature checks establish integrity without claiming verified ownership.
Clé utilisable covers unavailable/expired/revoked keys, and Motif introduces complete key-state reasons.
Names/address lists avoid forced elision after de; dates follow Dernière recherche. Original numeric
placeholders/selectors remain intact. Unencrypted sending is conditional on removing protected content.

Reviewed the new help topic and write-message insertion, with 19 improved help lines. Five older writing-help
passages were explicitly reopened and recorded: suggestions, subject entry, account selection, plain-text
sending and link-menu joins. All other earlier prose is retained. Help describes colors/status across platforms,
own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Glossary updated.

All 53 mnemonic scopes pass. The structural checker reports only 1,446 expected removed-mark diagnostics.
Exact reconstruction verifies 17 value edits and 40 mark removals; help tags, attributes, controls, platform
branches and literal keys are preserved. Joins inspected on all platforms. The old screenshot predates the
new controls; their wrapping/layouts were checked in source. No GUI run, test suites or builds.
All 28 inventories/current hashes reconcile: 20,865 unmarked messages, 10,459 changed help lines and 14 baseline
pairs. Since-start 1,293 entries/207 passages match the queue. HTML regenerated; git diff --check passes.
Fresh fetch confirms all seven audited source tips unchanged, with no new strings/languages. Existing source
imports and guide unchanged; root has no relevant edits. Other hardening/corpus work untouched.
Completed: 20,831 entries/798 topics; pending: 13,037/554; scope:33,868/1,352; historical improvements:3,595.
Dutch compose is next. REVIEWED remains unchanged.


### Dutch compose signing and encryption reviewed

Reviewed all 40 additions, retaining the 17 app labels and eight good core values while improving 15 core
values. Status describes protection bij het verzenden, signature checks without assuming verified ownership,
and bruikbare sleutels rather than any keys. Dates use Laatst gezocht; complete key-state reasons follow Reden.
Corrected literal encryption-for-a-key wording. Unencrypted sending requires removing inherited protected
text, images and attachments. Informal je/jij and existing terminology remain consistent.

Reviewed the new help topic and only the writing-help insertion, improving 15 help lines. Earlier writing-help
prose is preserved exactly. The help uses a color/status table across platform icons, includes own and unusable
keys, and explains the selected From key, recipient removal and encrypted drafts/sent copies. Glossary updated.
All 53 mnemonic scopes pass. Structural checker: 1,446 expected removed-mark diagnostics, no structural findings.
Exact reconstruction verifies 15 value edits and 40 mark removals. Help tags/attributes/controls/platform branches
and literal keys are preserved. Joins inspected on all platforms; no Dutch compose/encryption screenshot was
available in the three screenshot trees, so layouts/wrapping were checked in source. No GUI run, tests or builds.

All 28 inventories/current hashes reconcile: 20,905 unmarked messages, 10,479 changed help lines and 14 baseline
pairs. Since-start 1,253 entries/205 passages match the queue. HTML regenerated; git diff --check passes.
Seven source refs remain unchanged after fresh fetch. Also audited uncommitted locale/help/commands/settings/
registry paths in root, wave1, more-languages, settings, hardening and compose worktrees. Only the old five-language
copies in PostalExpress-lang were found: all 290 files exactly match initial snapshot cfdf55ab already imported.
There are no later edits/new strings in those copies. They remain untouched, with comparison provenance recorded.

Completed: 20,871 entries and 800 topics; pending: 12,997/552; scope:33,868/1,352; historical improvements:3,610.
Italian compose is next, followed by the recorded languages and remaining Hungarian help. REVIEWED is unchanged;
the complete queue and final late-arrival audit are still required.


### Italian compose signing and encryption reviewed

Reviewed 40 additions, retaining all 17 app labels and seven good core values while improving 16 core values.
Status describes protection all’invio, signature integrity without proof of ownership, and chiavi utilizzabili.
Removed literal encryption-for-a-key wording. Complete state reasons follow Motivo; date/address/count joins
remain natural. Downgrade warnings cover inherited text/images/attachments and conditional unencrypted sending.

Reviewed the new help topic and writing-help insertion, plus one explicitly reopened older plain-text paragraph
that promised identical display in all mail apps. It now describes compatibility; all other earlier prose is
retained. Fifteen help lines improved. Help explains colors/status, own/unusable keys, selected From key,
recipient removal and encrypted drafts/sent copies. Glossary updated.

All 53 shortcut scopes pass. Structural checker:1,446 expected removed-mark diagnostics, no structural findings.
Exact reconstruction verifies16 value edits/40 mark removals; help tags/attributes/controls/platform branches/
literal keys preserved. Joins inspected on all platforms; no Italian screenshot found, so controls/layouts were
checked in source. No GUI run, test suites or builds. All28 inventories/current hashes reconcile:20,945 unmarked
messages,10,499 changed help lines,14 baseline pairs. Since-start1,213 entries/203 passages match the queue.
HTML regenerated; git diff --check passes.

Fresh fetch/seven-ref audit found no new strings/languages. Six source worktrees have no new uncommitted relevant
changes; all290 old copies retain exact cfdf55ab contents. The reusable source-worktree audit helper and its
verified manifest provenance are recorded in state. Completed20,911 entries/802 topics; pending12,957/550;
scope33,868/1,352; historical improvements3,626. Portuguese is next. REVIEWED remains unchanged.


### European Portuguese compose signing and encryption reviewed

Reviewed all 40 additions, retaining all 17 app labels and seven good core values while improving 16 core values. Kept encriptar/ficheiro and polite third-person wording without você. Status describes protection no envio; signature integrity is distinct from verified ownership. Chave utilizável includes unusable keys, full key-state reasons follow Motivo and dates follow Última pesquisa. Unencrypted sending is conditional on removing inherited protected text, images and attachments.

Reviewed the new topic and only the writing-help insertion, improving 14 help lines. All earlier writing-help prose is preserved. Help describes color/status differences, own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Glossary updated.

All 53 mnemonic scopes pass. Structural checker:1,446 expected removed-mark diagnostics, no structural findings. Exact reconstruction verifies16 value edits and40 mark removals; all other catalog bytes preserved. Help tags/attributes/controls/platform branches/literal keys match. Joins inspected on all platforms; no Portuguese compose/encryption screenshots found, so controls/layouts/wrapping checked in source. No GUI run, test suites or builds. All28 inventories/current hashes reconcile:20,985 unmarked messages,10,519 changed help lines and14 verified baseline pairs. HTML regenerated; git diff --check passes.

Seven source refs unchanged after fetch, guide unchanged; no new strings/languages. Six source worktrees have no new uncommitted relevant changes; all 290 old draft copies retain exact cfdf55ab contents. Full inventories and since-start 1,173 entries/201 passages reconcile. No tests.
Completed 20,951 entries/804 topics; pending 12,917/548; scope 33,868/1,352; historical catalog improvements 3,642. Next: Brazilian Portuguese. REVIEWED remains unchanged.


### Brazilian Portuguese compose signing and encryption reviewed

Reviewed all 40 additions, retaining the 17 app labels and eight good core values while improving 15 core values. Kept Brazilian você, criptografia, arquivo and backup. Status describes protection no envio, usable keys and signature integrity without assuming verified ownership. Full key-state reasons follow Motivo; dates follow Última busca. Missing-key counts are positive, while zero recipients use a separate status. All selectors and numeric placeholders are preserved. Unencrypted sending requires removal of inherited protected text, images and attachments.

Reviewed the new topic and only the writing-help insertion, improving 14 help lines and preserving all earlier prose. Help covers per-platform color/status symbols, own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Glossary updated.

All 53 mnemonic scopes pass. Structural checker:1,446 expected removed-mark diagnostics, no structural findings. Exact reconstruction verifies15 value edits/40 mark removals and preserves other catalog bytes. Help tags/attributes/control references/platform branches/literal keys match. All platform label joins inspected; no Portuguese compose/encryption screenshots available, so source controls/layouts/wrapping inspected. No GUI run, test suites or builds. All28 inventories/current hashes reconcile:21,025 unmarked messages,10,539 changed help lines and14 verified baseline pairs. HTML regenerated; git diff --check passes.

Seven source refs unchanged after fetch, guide unchanged; no new strings/languages. Six source worktrees have no new uncommitted relevant changes; all 290 old draft copies retain exact cfdf55ab contents. Full inventories and since-start 1,133 entries/199 passages reconcile. No tests.
Completed 20,991 entries/806 topics; pending 12,877/546; scope 33,868/1,352; historical catalog improvements 3,657. Next: Catalan. REVIEWED remains unchanged.


### Catalan compose signing and encryption reviewed

Reviewed all 40 additions, improving 17 core values and two app access keys. Insert now uses Alt+N to avoid Tools; Find Key uses Alt+E to avoid Keep Current. Short commands retain imperative singular, while explanatory prose and tooltips use polite vós. Protection is applied en enviar-lo; signature integrity is distinct from verified ownership. Clau utilitzable covers unusable keys, complete reasons follow Motiu, and names/addresses need no forced article. Unencrypted sending depends on removing inherited protected text, images and attachments.

Reviewed the new help topic and only the writing-help insertion, improving 14 help lines. All earlier writing-help prose is preserved. Help covers platform-specific status symbols, own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Glossary updated.

All 53 mnemonic scopes pass. Structural checker: 1,446 expected removed-mark diagnostics, no structural findings. Exact reconstruction verifies 19 value edits and 40 mark removals; all other catalog bytes and earlier writing-help prose are preserved. Help tags, attributes, controls, platform branches and literal keys match. Platform label joins inspected; no relevant Catalan screenshots available, so source controls/layouts/wrapping inspected. No GUI run, test suites or builds. All 28 inventories/current hashes reconcile: 21,065 unmarked messages, 10,559 changed help lines and 14 verified baseline pairs. HTML regenerated; git diff --check passes.

Fresh fetch found origin/master advanced to cb5e4778, including hardening merge 3161dddc; chore/pgp-hardening advanced to 51d67bb4. All 87 help files and 29 core catalogs introduced upstream exactly match the already tracked help/signature source imports; no additional strings, edited translations or languages. The hardening-tip delta only changes a Windows UI-test wait. The guide is unchanged. Dependent hardening implementation is now on origin/master but remains outside this translation worktree; unrelated code/corpus changes were not merged. Six source worktrees have no new uncommitted relevant changes; all 290 old draft copies retain exact cfdf55ab contents. Full inventories and since-start 1,093 entries/197 passages reconcile. No tests.
Completed 21,031 entries/808 topics; pending 12,837/544; scope 33,868/1,352; historical catalog improvements 3,676. Next: Norwegian Bokmål. REVIEWED remains unchanged.


### Norwegian Bokmål compose signing and encryption reviewed

Reviewed all 40 compose additions. Retained 17 natural app labels and seven core values; improved 16 core values. Direct du wording describes protection when sending, signature checks without assuming verified identity, and brukbare nøkler. Complete key-state explanations follow Årsak, while date values follow Siste søk. Replaced literal encryption-to-a-key wording. Unencrypted sending requires removal of inherited protected text, images and attachments.

Reviewed the new help topic and writing-help insertion, improving 14 help lines. All earlier writing-help prose is preserved. Help explains status colors across platform icons, own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Glossary updated.

All 53 mnemonic scopes pass. Structural checker: 1,446 expected removed-mark diagnostics, no structural findings. Exact reconstruction verifies 16 value edits and 40 mark removals, preserving all other catalog bytes. Help tags, attributes, controls, platform branches and literal keys match; all prior writing-help prose is retained. Label joins inspected on all platforms and dynamic shortcuts checked in commands.toml. No relevant Norwegian screenshots available; source controls/layouts/wrapping inspected. No GUI run, test suites or builds. All 28 inventories/current hashes reconcile: 21,105 unmarked messages, 10,579 changed help lines and 14 verified baseline pairs. HTML regenerated; git diff --check passes.

Seven source refs unchanged after fetch, guide unchanged; no new strings/languages. Six source worktrees have no new uncommitted relevant changes; all 290 old draft copies retain exact cfdf55ab contents. Full inventories and since-start 1,053 entries/195 passages reconcile. No tests.
Completed 21,071 entries/810 topics; pending 12,797/542; scope 33,868/1,352; historical catalog improvements 3,692. Next: Serbian Latin. REVIEWED remains unchanged.


### Serbian Latin compose signing and encryption reviewed

Reviewed all 40 compose additions. Retained 17 natural app labels and seven core values; improved 16 core values. Kept Ekavian, formal plural prose, feminine agreement with poruka and protection pri slanju. Expanded the encrypted/missing statuses to exact [1] plus [one]/[few]/*[other], with numeric count placeholders and natural primalac/primaoca/primalaca forms. Signature checks remain distinct from ownership. Usable keys, complete Razlog explanations and Poslednja pretraga dates fit actual callers. Sending without encryption requires removal of inherited protected text, images and attachments.

Reviewed the new help topic and writing-help insertion, improving 14 help lines while preserving all earlier writing-help prose. Help covers cross-platform status symbols, own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Retained Žutonarandžasta to match existing reading-security help. Glossary updated.

All 53 mnemonic scopes pass. Structural checker: 1,446 expected removed-mark diagnostics, no structural findings. Exact reconstruction verifies 16 value edits and 40 mark removals; all other catalog bytes preserved. Plural selection inspected for 0,1,2,3,4,5,11,12,14,21,22,24,25,101, with representative value substitutions and actual positive-count callers/separate zero-recipient state checked. Help tags, attributes, controls, platform branches and literal keys match; all earlier writing-help prose retained. Platform label joins inspected and dynamic shortcuts checked in commands.toml. No relevant Serbian screenshots found; source controls/layouts/wrapping inspected. No GUI run, test suites or builds. All 28 inventories/current hashes reconcile: 21,145 unmarked messages, 10,599 changed help lines and 14 verified baseline pairs. HTML regenerated; git diff --check passes.

Seven source refs unchanged after fetch, guide unchanged; no new strings/languages. Six source worktrees have no new uncommitted relevant changes; all 290 old draft copies retain exact cfdf55ab contents. Full inventories and since-start 1,013 entries/193 passages reconcile. No tests.
Completed 21,111 entries/812 topics; pending 12,757/540; scope 33,868/1,352; historical catalog improvements 3,708. Next: Turkish. REVIEWED remains unchanged.


### Turkish compose signing and encryption reviewed

Reviewed all 40 compose additions, improving 16 core values and one app shortcut. Send Without Encryption now uses Alt+N, avoiding Keep Current Alt+G and Turkish dotted/dotless I. Polite imperative wording, singular nouns after counts, and head nouns or colons keep names/addresses free of suffixes. Protection is applied gönderilirken; digital-signature checks do not imply verified ownership. Kullanılabilir anahtar covers unusable keys. Complete reasons follow Neden and dates follow Son arama. Replaced literal encryption-to-a-key wording and made unencrypted sending conditional on removal of inherited protected text, images and attachments.

Reviewed the new help topic and writing-help insertion, improving 14 wording lines. The unchanged heading also loses its inline review mark; that is not counted as a wording change. All earlier writing-help prose retained. Help covers cross-platform status symbols, own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Kehribar retained to match reading-security help. Glossary updated.

All 53 mnemonic scopes pass; the changed label maps to GTK Şifrelemeden Gö_nder through the actual gtk_mnemonic caller. Structural checker: 1,446 expected removed-mark diagnostics, no structural findings. Exact reconstruction verifies 17 value edits and 40 mark removals; all other catalog bytes preserved. Help tags, attributes, controls, platform branches and literal keys match; all earlier writing-help prose retained. Platform joins inspected; dynamic shortcuts checked against commands.toml. No relevant Turkish screenshots found, so source controls/layouts/wrapping inspected. No GUI run, test suites or builds. All 28 inventories/current hashes reconcile: 21,185 unmarked messages, 10,619 changed help lines and 14 verified baseline pairs. HTML regenerated; git diff --check passes.

Seven source refs unchanged after fetch, guide unchanged; no new strings/languages. Six source worktrees have no new uncommitted relevant changes; all 290 old draft copies retain exact cfdf55ab contents. Full inventories and since-start 973 entries/191 passages reconcile. No tests.
Completed 21,151 entries/814 topics; pending 12,717/538; scope 33,868/1,352; historical catalog improvements 3,725. Next: Bulgarian. REVIEWED remains unchanged.


### Bulgarian compose signing and encryption reviewed

Reviewed all 40 compose additions, improving 16 core values and one app shortcut. Find Key now uses Cyrillic Alt+К, avoiding Use New Key Alt+Н. Kept verbal-noun controls/tooltips and polite plural explanations. Protection is applied при изпращане; digital signatures do not by themselves confirm ownership. Използваем ключ includes unusable keys; complete reasons follow Причина and dates follow Последно търсене. Counts use the ordinary plural получатели for people. Replaced literal encryption-for-a-key wording and explained when inherited protected text, images and attachments prevent unencrypted sending.

Reviewed the new help topic and writing-help insertion, improving 14 wording lines. The unchanged heading also loses its inline review mark, excluded from the wording count. All earlier writing-help prose is preserved. Help describes platform status symbols, own/unusable keys, the selected From key, recipient removal and encrypted drafts/sent copies. Kept Кехлибарен consistent with reading-security help and quoted the folder name Изпратени. Glossary updated.

All 53 mnemonic scopes pass; GTK label Намиране на _ключ checked against the actual conversion. Structural checker: 1,446 expected removed-mark diagnostics, no structural findings. Exact reconstruction verifies 17 value edits and 40 mark removals; all other catalog bytes preserved. Help tags, attributes, controls, platform branches and literal keys match; all earlier writing-help prose retained. Platform joins inspected and dynamic shortcuts checked in commands.toml. No relevant Bulgarian screenshots found, so source controls/layouts/wrapping inspected. No GUI run, test suites or builds. All 28 inventories/current hashes reconcile: 21,225 unmarked messages, 10,639 changed help lines and 14 verified baseline pairs. HTML regenerated; git diff --check passes.

Seven source refs unchanged after fetch, guide unchanged; no new strings/languages. Six source worktrees have no new uncommitted relevant changes; all 290 old draft copies retain exact cfdf55ab contents. Full inventories and since-start 933 entries/189 passages reconcile. No tests.
Completed 21,191 entries/816 topics; pending 12,677/536; scope 33,868/1,352; historical catalog improvements 3,742. Next: Czech. REVIEWED remains unchanged.
