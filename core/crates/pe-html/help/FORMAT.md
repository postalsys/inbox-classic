# Help topics

The help is one topic a file: `help/<language>/<id>.html` (en, de, es, et, fr), each a fragment in a small subset of
HTML, and `help/topics.toml`, which orders the topics into sections. `pe-html` (`help.rs`) turns a topic into the
page each platform shows: in the app's help viewer on Windows and Linux, in the Mac's Help Book, in Yelp (Mallard) and
on inboxclassic.com/help.

## A topic

```html
<h1>Find messages</h1>
<p class="summary">Search every folder of every account at once, or one folder.</p>
<p>To find a message:</p>
<ol>
    <li>Click the search box at the right of the toolbar, or press <kbd data-command="find_message"></kbd>.</li>
    <li>Type a word from the message. The list shows the messages that match, with the folder each is in.</li>
</ol>
<aside class="note">Search looks at the mail on this computer, so it works offline.</aside>
<nav class="related"><a href="topic:search-words"></a> <a href="topic:conversations"></a></nav>
```

- `<h1>`: the topic's title, once, first.
- `<p class="summary">`: one sentence, second; search results and the Help Book's index show it.
- Then only: `h2`, `p`, `ol`, `ul`, `li`, `table`, `tr`, `th`, `td`, `aside class="note"` (or `class="warning"`), `b`,
  `i`, `code`, `kbd`, `a`, `img`, `br`.
- `<kbd data-command="mark_read"></kbd>`: the shortcut of a command of `core/commands.toml`, written as the platform
  writes it (Ctrl+Q on Windows and Linux, ⌘⇧U on the Mac, Strg in German). Never type a key by hand that a command
  has; other keys as `<kbd>Esc</kbd>`, `<kbd>Ctrl</kbd>+<kbd>Click</kbd>` inside an `os` part when they differ.
- `<b data-text="cmd-mark-read"></b>`: a control named by its catalog message (`core/locales/<lang>/*.ftl`), as the
  app names it in the language, without its access key's `&`. Use it for every menu command, button and field name.
  A menu path: `<b data-text="menu-file"></b> &gt; <b data-text="cmd-new-account"></b>`.
- `<a href="topic:<id>"></a>`: a link to another topic; left empty, it is filled with that topic's title.
  `<a href="https://...">` opens in the browser.
- `<img src="picture:<shot>" alt="...">`: a screenshot of the UI tests (`read-1-html`, `account-1-form`,
  `agents-4-send`, `bounce-1-failed`, `all-inboxes-3-accounts`), the platform's own.
- `<!--os:windows,linux-->...<!--/os-->`: a part for some platforms only (windows, mac, linux), not nested.
- `<!--review-->...<!--/review-->` in a translation: a passage waiting for a native review.

## Style

1. One task or one idea a topic, under about 300 words.
2. A task starts with "To ...:", then numbered steps; each step one action, then what happens.
3. Sentences under 25 words; "you", active voice, present tense.
4. Controls in bold by their catalog names (`data-text`); keys only through `data-command` where a command has one.
5. Protocol names and RFCs only in the Privacy and security or Advanced topics, never in steps.
6. The app's typography: ’ and “ ”, "cannot", US spelling (color, gray). The Mac says Trash, Finder, Settings.
7. A warning in a note before the step it warns about.
8. Tables for reference only (keys, search words, errors).
9. Up to three related topics at the end.

## Generated parts

- `<div data-generate="shortcuts"></div>`: the table of every command with a key, from `core/commands.toml`, by menu,
  in the language and the platform's way of writing keys. The Keyboard shortcuts topic uses it, with the keys that are
  no command (in lists, the editor, the Address Book) written after it by hand.
