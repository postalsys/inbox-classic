# Six more languages: Japanese, Chinese, Korean, Indonesian, Vietnamese

Wave 2 of the languages after `languages-wave1-plan.md`: the first outside Europe. All six are written left to right, so the windows need no mirroring; right to left (Arabic, Hebrew, Persian, Urdu) is a later wave and not in this plan. Unlike wave 1, these need more than translation: Japanese and Chinese write words without spaces between them, which the search index does not handle today, their menus write access keys differently, and Windows needs the right font.

Reviewed against the code twice on 2026-11-21; what the second review changed is in "What the review corrected" at the end.

## Decided

| Question            | Answer (2026-11-21)                                                                                                                                                                      |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Which languages     | Japanese, Simplified Chinese, Traditional Chinese, Korean, Indonesian, Vietnamese                                                                                                        |
| Right to left       | Not in this plan                                                                                                                                                                         |
| Hindi               | Not in this wave: Indian desktop users mostly run their computers in English. It goes into a later South Asian wave with Bengali and others                                              |
| Chinese             | Both scripts, two catalogs: `zh-Hans` and `zh-Hant`                                                                                                                                      |
| Traditional Chinese | One catalog in Taiwan's usage (檔案, 郵件, 資料夾), not a character-by-character conversion of Simplified. Hong Kong and Macau get the same catalog                                      |
| Sent mail           | Always UTF-8, also in Japanese: no ISO-2022-JP for old Japanese mail programs. Reading it is already supported                                                                           |
| Windows font        | For these languages always the font Windows itself uses in them (Yu Gothic UI, Microsoft YaHei UI, Microsoft JhengHei UI, Malgun Gothic), chosen by the core, not font linking by chance |
| Undeclared charsets | No detection: a message that declares no charset is read as UTF-8, as postal-mime does, so pe-mime stays its port. Old CJK mail without a charset stays unreadable                       |

## Defaults chosen (say if you want otherwise)

- **Tags**: `ja`, `zh-Hans`, `zh-Hant`, `ko`, `id`, `vi`. A system in `zh-CN`, `zh-SG` or `zh-Hans-*` gets `zh-Hans`; `zh-TW`, `zh-HK`, `zh-MO` or `zh-Hant-*` gets `zh-Hant`; plain `zh` gets `zh-Hans`. Indonesian also answers to the old code `in`. The Options list names them in their own words: 日本語, 简体中文, 繁體中文, 한국어, Bahasa Indonesia, Tiếng Việt.
- **Access keys** follow each platform's own convention for these languages. The catalog writes `ファイル(&F)`, with a Latin letter in brackets at the end, as Japanese, Chinese and Korean Windows does. Windows and Linux show it that way: `ファイル(F)`, with the F underlined. The Mac, which has no access keys, drops the whole bracket, as Apple's own Japanese menus do. Indonesian and Vietnamese mark a letter of the word, as the European languages do.
- **Full width letters and digits** (ＡＢＣ１２３, common in Japanese mail) are searched and sorted as ABC123: the store's `fold` takes them as their ASCII forms, as it takes Turkish ı as i.
- **A message's own language for its characters**: Japanese and Chinese share many characters that each draws differently. The reading pane's document gets a `lang` from the message's charset (ISO-2022-JP and Shift_JIS: Japanese; GB18030: Simplified; Big5: Traditional; EUC-KR: Korean), else the app's language, so a Japanese message is not drawn in Chinese forms.
- **Sorting** by subject or sender stays by code point for Han, kana and Hangul, as most mail programs do: no sorting by reading (Japanese) or stroke count (Chinese).
- **The order of work with the other plan**: `action-buttons-plan.md` changes and removes strings, so its two pull requests merge before this plan's translations (PR 3), and the six languages translate the final words once.
- Every draft is marked for review, as before, with the honesty rule of wave 1 (a draft that would not be a good start is skipped and the reason given), and board post #2 gets a comment asking native reviewers for these six.

## What is ready already

Checked in the code on 2026-11-21:

- **Reading mail**: pe-mime decodes Shift_JIS, ISO-2022-JP, EUC-KR, GB18030 and Big5 when the message declares them (`charset.rs`, through encoding_rs).
- **Sign-in codes**: pe-otp's keywords already include Simplified and Traditional Chinese (验证码, 驗證碼), Japanese (認証コード) and Korean (인증번호, 인증 코드).
- **Help search** matches a word anywhere in the text (`help.rs` `help_search`), so it already finds Chinese and Japanese words.
- **Plurals**: `pe_i18n` takes each tag as its own plural locale; these six have only the `other` form and need nothing added.
- **Help pages** carry `<html lang>`, so a Japanese page draws Japanese forms of the shared characters.
- **Initials** in the list take a Chinese name's first character (`text.rs` `initials`).
- **Dates and times** come from the system's own formats on each platform (`GetDateFormat`, `DateFormatter`, GLib), not from the catalogs, so they need no work; the tours check them.
- **Conversations** are grouped by Message-IDs, never by subject, so foreign reply prefixes do not split them.
- **A SQL function of ours in the index** is nothing new: `fold` (pe-store `fold.rs`) is registered on every connection and used by the store's indexes and triggers. The search change below adds to it.

## The work

### 1. Search that finds words without spaces (core, first)

The search index (`messages_fts`, FTS5 with `unicode61`) makes a word of every run of letters between spaces. A Chinese or Japanese sentence is therefore one long "word", and searching for a word inside it finds nothing. Korean has spaces, but its words carry endings (회의에서, "at the meeting"), so 회의 is not found either. This hurts anyone who gets mail in these languages today, whatever language the app is in.

- A SQL function `segment(text)` beside `fold` in pe-store (`fold.rs`, rusqlite's `functions`, no `unsafe`) puts a space between characters of Han, Hiragana, Katakana and Hangul, and writes full width letters and digits as ASCII. Each such character becomes a word of the index; other text passes unchanged. It is a pure function over a string, tested by itself.
- The index's trigger (`fts_columns` in `search.rs`) and the body text the workers index both go through it.
- A search with such characters becomes a phrase of the characters: 会议 becomes `"会 议"`, which FTS5 matches only where the two stand next to each other in that order. That is substring search, so a word is found inside a longer word, and so are names. One character alone is a plain word match. A full width space (U+3000) separates words as a space does.
- The phrase is built from characters only and quoted as every FTS5 word is now (`fts_word`), with bound values: no part of a query or a message becomes SQL or FTS5 syntax.
- A migration (a new entry in `MIGRATIONS`) rebuilds the trigger and indexes again the messages with such characters in their subject, senders, recipients, file names or snippet: from the cached source where there is one, read again by the workers otherwise. This is what the dotless ı migration did.
- `query.rs` and `search.rs` build the phrases; the Gmail query syntax is unchanged.
- **Address completion** (`contacts.rs`) matches the start of a word of a name. A Chinese or Japanese name has no spaces, so what is typed in such characters matches anywhere in the name (张伟 by 伟).

### 2. Subjects and quoted text in these languages (core)

- **Reply and forward prefixes**: `prefixed` (`compose.rs`) knows `Re:`, `Fw:` and `Fwd:` only. It learns the prefixes Chinese, Japanese and Korean mail programs write (`回复:`, `答复:`, `回覆:`, `转发:`, `轉寄:`, `転送:`, `返信:`, `회신:`, `전달:`), and the full width colon (`RE：`), so a reply does not become `Re: 回复: ...`. Our own prefix stays `Re:`.
- **pe-content** (separating what a sender wrote from the reply history): check that it recognizes the quote headers of Chinese, Japanese and Korean mail programs (`... 写道：`, `... さんは書きました:`, `... 작성:`, Outlook's `发件人:` and `差出人:` blocks). What is missing goes into email-content first, then the port, so the two stay in step and `tests/conformance.rs` keeps comparing them.
- **pe-otp**: check the keywords still missing: Japanese 確認コード and ワンタイムパスワード, Vietnamese (mã xác minh, mã OTP) and Indonesian (kode verifikasi). What is missing goes into otp-detect first, then the pinned port and its fixtures.
- **The reading pane's `lang`** from the message's charset, as the defaults say (`pe-html`, the document wrapper).

### 3. The language list and the platforms

- The six tags in `pe_i18n::LANGUAGES`, with the matching of a system's tag above. Tests of matching: `zh-CN`, `zh-TW`, `zh-HK`, `zh-Hans-CN` (the Mac's form), `zh_TW.UTF-8` (Linux's), `in`, `ja-JP`.
- `without_mnemonic` drops a bracketed access key (`(&F)`, also with a space before it) for the Mac and for the help's control names; `gtk_mnemonic` turns it into `(_F)`. `scripts/check-language.mjs` and the mnemonic scope check accept the bracket form for these three languages, and the bracketed letter must be unique in each scope as it is now.
- **Windows**: the classic controls use `DEFAULT_GUI_FONT`, which on an English Windows is MS Sans Serif and reaches CJK glyphs only through font linking. For Japanese, Chinese and Korean the window font is instead the one Windows itself uses in that language: Yu Gothic UI, Microsoft YaHei UI, Microsoft JhengHei UI, Malgun Gothic, at the size the classic look uses. The core names the face for the language in use (a constant of ours, never a value from mail), and every place that takes `DEFAULT_GUI_FONT` today (the main window, the address book, the agents window, the help toolbar, compose) takes the app's window font instead. Indonesian and Vietnamese keep the default font.
- **Typing with an input method (IME)** on all three: the search box searches as you type, on a timer, and must not search half-composed text or take the Enter that confirms a composition; the address fields' completion list must not take that Enter or the arrow keys either. Checked by hand on each platform (the list is in Tests).
- **The Mac**: `.lproj` folders `ja`, `zh-Hans`, `zh-Hant`, `ko`, `id`, `vi`; the Help Book in each.
- **Linux**: desktop entry and metainfo in `ja`, `zh_CN`, `zh_TW`, `ko`, `id`, `vi`; Yelp's pages. The Docker image for the UI test gets `fonts-noto-cjk`, so the screenshots show the text; the packages leave fonts to the system, which every desktop that offers these languages installs.
- **The installer**: NSIS's own translations of its pages where NSIS has them, English for the rest.
- **The sign-in buttons**: `build-sign-in-buttons.sh` takes the fonts these scripts need (Noto Sans JP, SC, TC and KR, OFL, fetched and checked by hash as the others are), since Roboto and Segoe's stand-in have no CJK.
- **The homepage help** (`homepage-help.sh`) builds the six languages; the language picker lists them.

### 4. The translations

About 1,460 messages and 53 help topics a language. Six translators in parallel, with the brief and the checker the earlier languages used. In each catalog's glossary section, the words Windows itself uses in that language: Outlook Express's own terms where there was a version in that language (受信トレイ, 收件箱, 收件匣, 받은 편지함), which is the voice of the Windows app. Every message and help passage marked for review. The checker additionally flags full width punctuation mixed with ASCII in one message, and spaces around placeables in Chinese and Japanese, where the sentence has none.

### 5. Language tours

Each platform's UI test already visits every language: these six are added, with screenshots of the main window, Options and compose. Check that nothing is cut off: Vietnamese and Indonesian labels are long, and CJK labels are short but taller. Check that text wraps in the right places in dialogs, where Windows' `DrawText` and the GTK and AppKit labels must break CJK lines between characters, and that dates read as the language's own.

## Tests

Every new function gets a test where it is written, and each pull request's description lists what is covered by which test and what is checked by hand.

**Unit tests (core)**

- `segment`: Han, Hiragana, Katakana, Hangul, mixed with Latin, full width letters and digits, combining marks, surrogate-pair Han (the rare characters beyond U+FFFF), an empty string; Latin, Cyrillic and Greek text unchanged, so the 29 languages' search does not move. A property test: for random strings, joining the pieces without their spaces gives the folded input back.
- Query building: a CJK word as a phrase; a mixed `会议 report` query as two terms; one character; a quoted phrase; operators (`subject:会议`, `-会议`, `OR`); U+3000 as a space; a quote or an asterisk inside the query stays text.
- The migration: a store made by the release before it, with CJK and Latin messages, comes out with both found, body text indexed again from cached sources, and the others queued for the workers.
- `kept_check.rs` (counts and conversations after random writes) with CJK subjects among the random ones, since the index trigger changed.
- `prefixed`: each foreign prefix and the full width colon; `Re:` behaviour unchanged.
- Address completion: 张伟 by 伟 and by 张; Latin names still match by word starts only.
- pe-i18n: tag matching for every form listed above; `without_mnemonic` and `gtk_mnemonic` with brackets, with and without a space, and `&&`; plural forms of the six tags.
- pe-html: the `lang` of the reading pane's document for each charset and for none.

**Conformance and fuzzing**

- pe-content and pe-otp: fixtures regenerated from the updated email-content and otp-detect, so `tests/conformance.rs` compares the new cases too.
- A fuzz target `store_segment` in `core/fuzz` for `segment` and the query builder (they see every message's text and whatever is typed), with its corpus, as the other targets have.

**Speed**

- `list_speed.rs` (CI's `list-speed`, 229,000 messages): a share of the messages gets CJK subjects and text; every list and search call keeps its budget, and the index's size is recorded in the PR.

**End to end, the core against ImapKit** (`pe-core/tests/e2e_core.rs`, `pe-ffi/tests/e2e_ffi.rs`)

- Messages in ISO-2022-JP, GB18030, Big5, EUC-KR and UTF-8 are appended on the server, synced, their text fetched in the background, and found by a word in the middle of the subject and of the body, through the C API too.
- A search in such characters gives the same messages as ImapKit's own `SEARCH` for the same word, the server's truth the deep test compares with.
- A reply to a `回复:` message keeps one prefix on the server's copy in Sent Items.

**End to end, the three apps** (`scripts/ui-e2e/SCENARIO.md`, each platform's UI test, `feature-map.mjs`)

- A new scenario step: a Japanese and a Chinese message in the list; typing a word from the middle of the subject in the search box finds it; the reading pane shows it; screenshots `search-cjk-1`, `read-cjk-1`. In `feature-map.mjs` as a feature of all three.
- The language tour of step 46 visits the six languages: main window, Options, compose, Add Mail Account with the sign-in buttons; screenshots reviewed one by one for cut-off labels, boxes in place of characters, wrong line breaks and the access keys' brackets (shown on Windows and Linux, absent on the Mac).
- Windows: the tour runs on the build machine's English Windows, which is the case the font choice is for.
- The help in each language: the contents, one topic and a search (a word without spaces) in the help window, the Help Book and Yelp.

**The deep test** (`pe-deep`, `deep.yml`)

- The mailbox the walk seeds gets CJK subjects and bodies, so the walk's search steps, which compare every operator with the server's truth, cover segmented search under late answers, dropped connections and fast typing. A deep run on all four targets passes before PR 1 merges.

**By hand, with a list in the PR** (the tests can not type through an IME)

- Japanese (romaji to kana to kanji), Chinese (Pinyin) and Korean (2-set) input on each platform in: the search box, To and Subject, the editor, the Find dialogs, a folder's name. For each: composing shows inline, Enter confirms the composition and does not send, search or pick a completion, and Esc cancels the composition only.

**Translations**

- `check-language.mjs` for each; the core's catalog, plural and help tests over every language (`cargo test -p pe-i18n -p pe-html -- --include-ignored`); `i18n-review.mjs` shows every new passage marked.

## How it is done

Three pull requests, each on all three platforms where it touches them:

1. Search without spaces and what else is core only (steps 1 and 2): useful on its own, for everyone who gets such mail.
2. The six tags, the access key handling, the Windows window font and platform registration (step 3), with English placeholders.
3. The six translations and their tours (steps 4 and 5), drafts marked for review, after `action-buttons-plan.md` has merged.

**Before each commit**, in this order, with what they find fixed:

1. `/simplify`, with a look at the functions that grew (`search.rs` `condition`, `fts_columns`; each app's font setup).
2. `/security-review`, and the work goes on in the same turn afterwards. What it looks at in each: PR 1, that message text and typed queries reach SQLite only as bound values and quoted FTS5 words, that `segment` can not be made to produce FTS5 syntax, and that the migration reads no message it should not; PR 2, that the system's locale tag is parsed strictly and that font names are constants; PR 3, that translated help keeps the markup of `help/FORMAT.md` (no new links, no scripts, placeholders intact), which the checker and pe-html's tests enforce.
3. `cargo fmt`, clippy with `-D warnings`, prettier on Markdown and YAML.
4. The test suites: `cargo test --workspace` on the Mac, `scripts/win-test.sh` on Windows, `scripts/linux-test.sh`; the three UI tests (`win-ui-e2e.sh`, `mac-ui-e2e.sh`, `linux-ui-e2e.sh`) with `feature-map.mjs --check` for each.

**After each push**: CI watched to the end (fmt, clippy, generated files, tests on three systems, the three apps' builds and UI tests, `list-speed`, `check-shells.sh`); a real failure fixed and pushed, a flaky one rerun at most three times. PR 1 also waits for a green deep run. The UI changes of PR 2 and 3 go through the UX review loop: every screenshot read, fixed and read again until nothing is left.

No release with these languages until you have reviewed the translations or decided to ship the drafts marked as such.

## Not in this plan

- Charset detection for mail that declares none (decided above).
- ISO-2022-JP for sent mail (decided above).
- Sorting by reading or stroke count; word-aware search (finding 東京 but not 京都 inside 東京都 is the price of substring search, as in most mail programs).
- Thai, which needs the same search change plus line breaking by dictionary; Hindi and the right to left languages.

## What the review corrected

The second review, against the code, changed these from the first draft:

- Plurals need no table entries; the first draft said they did.
- pe-otp already knows Traditional Chinese and Japanese keywords; fewer are missing.
- Conversations never group by subject, so the prefix work is in `prefixed` only.
- Dates come from the system, not the catalogs: nothing to translate or format.
- `segment` joins the existing `fold` function instead of being a new mechanism, and also folds full width letters and digits.
- Added: the reading pane's `lang` by charset, IME rules for the search box and completion, the order with the action buttons plan, the fuzz target, the deep test's seed and the tests listed above.
