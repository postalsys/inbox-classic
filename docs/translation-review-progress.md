# Translation review, round 10

## Resume here

Authoritative checkout: `/Users/andris/Projects/PostalExpress`, local `master`. The selected-message wording review
is complete; commit the content, advance `core/locales/REVIEWED`, confirm zero pending changes, and archive this round.
Commit locally without pushing. Round 9 remains archived separately.

## Reviewed wording

Reviewed the selected-message action paragraph in English and all 34 translations, with the target languages
processed in parallel. Removed the claim that the selected message has a colored edge. The help now refers to the
selected message without depending on its border color; Windows uses an etched frame. The preceding instruction
already explains how to select a message. Added the same decision to the glossary.

Scope: **35 reviewed and changed help paragraphs in 35 files; zero full-topic reviews and zero catalog changes**.
All tags, references, keyboard text, platform branches and text outside the exact paragraphs are unchanged.
The complete 2,135-file inventory still contains 35 languages, with six catalogs and 55 help topics per language.
No new language or translation changes arrived during this round.

## Latest code check and remaining follow-up

The Windows View menu fix is implemented in [PR #275](https://github.com/postalsys/inbox-classic/pull/275),
commit `59302b679d19ae63e9125ebebf0568ff6c303f46`, but remains unmerged. It adds the four existing translated
conversation commands and introduces no new strings. Local and remote master still lack those menu items.
Keep the current Mac/Linux branch around the menu instructions until that fix is integrated. After integration,
enable the already-translated paragraph on Windows in all 35 help files and update the glossary's platform note.
No application code was changed in this translation round.

## Validation and evidence

Exact before/after paragraph ledgers and file hashes cover every reviewed language. The final audit authenticated
all 2,135 catalog/help files: the 35 reviewed files match their ledgers and the other 2,100 files are unchanged.
All 34 static language checkers reported zero structural findings; each produced only its 1,681 expected
missing-draft-mark diagnostics (1,626 catalog entries and 55 help topics, already reviewed). No pending review
marks remain. These checks do not constitute native-speaker approval.

No tests, builds, GUI runs or CI checks were run, as requested. Evidence is saved under the ignored
`build/i18n-round10-20261127/` directory, including `final-audit.json` and `late-arrival-audit.json`.
