# Five more languages: Brazilian Portuguese, Turkish, Norwegian, Catalan, Serbian

After the 19 languages of feature board #2, the next five that need nothing but translation: they use the Latin script, which everything already supports. The suggestions behind them are in `more-languages-overview.html`.

## Decided

| Question           | Answer                                                                                                                                                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Which languages    | Wave 1 only: Brazilian Portuguese, Turkish, Norwegian (Bokmål), Catalan, Serbian. Japanese, Chinese and Korean (with a search index for text without spaces) and Arabic, Hebrew and Persian (with right to left) are not in this plan |
| When               | Alongside the current work, as the 19 were: the translations do not need the test machines until the language tours                                                                                                                   |
| Serbian            | Latin script only (Srpski)                                                                                                                                                                                                            |
| Chinese, for later | Both Simplified and Traditional, if a CJK wave is planned                                                                                                                                                                             |

## Defaults chosen (say if you want otherwise)

- **Brazilian Portuguese** is its own catalog, `pt-BR`, beside Portugal's `pt`. The Options list shows "Português (Brasil)" and "Português (Portugal)". A system in Brazilian Portuguese gets `pt-BR`; any other Portuguese system (Portugal, Angola, Mozambique) gets Portugal's. The language code becomes a region-aware tag in `pe_i18n::LANGUAGES` (the first two-letter-plus-region entry); the installer, the Mac's localizations and Linux's desktop files take `pt_BR` / `pt-BR` as each expects.
- **Norwegian** is Bokmål, code `nb` (Nynorsk, `nn`, is a separate language and not in this plan). A system set to plain `no` or `nb` gets it.
- **Serbian** in Latin script, code `sr-Latn` (Srpski). A system in Serbian gets it whichever script the system uses.
- **Turkish**: the dotted and dotless i in case-insensitive matching (search, sorting, the address completion) checked with Turkish words; nothing in the core lowercases with the system's locale, so this should hold, and a test proves it.
- **Catalan** with its own plural rule (one, other) and apostrophe contractions (l'Arxiu, d'Inbox Classic) handled by rephrasing around placeables.
- Every draft is marked for review, as the 19 are; the board post #2 gets a comment asking native reviewers for these five too.

## The work

1. **Region tags in the language list** (`pt-BR`, `sr-Latn`): `pe_i18n::LANGUAGES` takes them, `supported()` and `resolve()` match a system's tag by language and then by region or script (`pt-BR` before `pt`; `sr-Cyrl-RS` and `sr-Latn-RS` both to `sr-Latn`; `no` and `nb` to `nb`), and every generated list (installer, Windows resources, Mac localizations, Linux desktop and metainfo, sign-in pictures, homepage help, the tests' tours) writes each tag the way its platform expects. Tests of the matching.
2. **The five translations** in parallel, one translator each, with the brief and checker the 19 used (`scripts/check-language.mjs`). Brazilian Portuguese starts from Portugal's catalog and changes what differs (ficheiro to arquivo, ecrã to tela, guardar to salvar, você); the others from English.
3. **Registration**: the five in the list, the sign-in button pictures, the glossary sections, the core and Linux and Mac builds.
4. **Language tours** in each platform's UI test (they already visit every language), the longest words checked for cut-offs.
5. **Turkish check**: a core test that search, sorting and the address completion treat İ/i and I/ı as Turkish users expect.

## Tests

`check-language.mjs` for each; the core's catalog, plural and help tests over every language; tests of matching a system's language tag to `pt-BR`, `pt`, `nb` and `sr-Latn`; the Turkish matching test; the three platforms' language tours with screenshots of the longest words.

## How it is done

As the 19: translators write only their own folders, every message and help passage marked for review, Maltese and Irish style honesty (a language whose draft would not be a good start is skipped and said so). One pull request with the region tags first, then one with the five languages; /simplify and /security-review (the tag matching reads the system's locale) before each. No release until you have reviewed the translations.
