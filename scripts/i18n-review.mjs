#!/usr/bin/env node
// The translations waiting for a native review. A message of a Fluent catalog (core/locales/<lang>/*.ftl) is new or
// changed when its English or its translation is not, as a pair, in the catalogs of the commit in
// core/locales/REVIEWED (the last native review; a message moved to another id or file counts as reviewed). Such a
// message carries `# review: new` or `# review: changed` on the line above it; a new or changed passage of a help page
// (core/crates/pe-html/src/help.<lang>.html) sits between <!--review--> and <!--/review-->.
//
//   node scripts/i18n-review.mjs                       lists what waits for a review, by language
//   node scripts/i18n-review.mjs --html out.html       the same as a page, English and the draft side by side
//   node scripts/i18n-review.mjs --check               fails when a new or changed message or help passage has no mark
//
// Once the drafts are reviewed: remove their marks, and when none are left, put the commit in core/locales/REVIEWED.

import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const locales = join(root, 'core/locales');
const helpDir = join(root, 'core/crates/pe-html/src');
// every language there is a catalog of but the English one, which is the source
const languages = readdirSync(locales, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && entry.name !== 'en')
    .map(entry => entry.name)
    .sort();
const MARK = /^#\s*review:\s*(\S+)\s*$/;
const REVIEW_START = '<!--review-->';
const REVIEW_END = '<!--/review-->';

const args = process.argv.slice(2);
const checking = args.includes('--check');
const htmlAt = args.indexOf('--html');
const htmlOut = htmlAt >= 0 ? args[htmlAt + 1] : null;

const reviewed = readFileSync(join(locales, 'REVIEWED'), 'utf8').trim();

function git(...rest) {
    return execFileSync('git', rest, { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
}

// the messages of a catalog: id, its text (with its continuation lines and attributes), and its review mark
function parse(text) {
    const messages = new Map();
    const lines = text.split('\n');
    let current = null;
    let comments = [];
    for (const line of lines) {
        const start = /^([a-zA-Z][a-zA-Z0-9_-]*)\s*=(.*)$/.exec(line);
        if (start) {
            const mark = comments.map(c => MARK.exec(c)).find(Boolean);
            current = { id: start[1], text: start[2].trim(), mark: mark ? mark[1] : null };
            messages.set(current.id, current);
            comments = [];
        } else if (current && /^\s+\S/.test(line)) {
            current.text += '\n' + line.trim();
        } else if (line.startsWith('#')) {
            current = null;
            comments.push(line);
        } else if (!line.trim()) {
            // a blank line inside a message's indented lines is part of it (a paragraph break); a comment above a
            // blank line belongs to no message
            if (current) {
                current.text += '\n';
            }
            comments = [];
        } else {
            current = null;
        }
    }
    return messages;
}

// the messages of every catalog of `language`, by id, as they are now or (with `commit`) as they were then
function catalogs(language, commit = null) {
    let files;
    let read;
    if (commit) {
        try {
            files = git('ls-tree', '--name-only', `${commit}:core/locales/${language}`).split('\n');
        } catch {
            return new Map();
        }
        read = file => git('show', `${commit}:core/locales/${language}/${file}`);
    } else {
        files = readdirSync(join(locales, language));
        read = file => readFileSync(join(locales, language, file), 'utf8');
    }
    const all = new Map();
    for (const file of files.filter(f => f.endsWith('.ftl'))) {
        for (const [id, message] of parse(read(file))) {
            all.set(id, { ...message, file });
        }
    }
    return all;
}

const englishNow = catalogs('en');
const englishThen = catalogs('en', reviewed);

const waiting = [];
const unmarked = [];
for (const language of languages) {
    const now = catalogs(language);
    const then = catalogs(language, reviewed);
    // the pairs (English, translation) the review saw: under the same id, or under an id that is gone now (a message
    // moved to another id or file). The same words reviewed in another place do not count, the context differs.
    const pair = (english, message) => `${english.text}\u0000${message.text}`;
    const moved = new Set();
    for (const [id, message] of then) {
        const english = englishThen.get(id);
        if (english && !now.has(id)) {
            moved.add(pair(english, message));
        }
    }
    for (const [id, message] of now) {
        const english = englishNow.get(id);
        if (!english) {
            continue;
        }
        const before = then.get(id);
        const beforeEnglish = englishThen.get(id);
        const seen = (before && beforeEnglish && pair(beforeEnglish, before) === pair(english, message)) || moved.has(pair(english, message));
        const entry = { language, file: message.file, id, english: english.text, draft: message.text, mark: message.mark };
        if (message.mark) {
            waiting.push(entry);
        } else if (!seen) {
            unmarked.push({ ...entry, kind: then.has(id) ? 'changed' : 'new' });
        }
    }
}

// a help page: its lines that are not in the reviewed page must be inside review marks
const helpWaiting = [];
const helpUnmarked = [];
for (const language of languages) {
    const path = join(helpDir, `help.${language}.html`);
    if (!existsSync(path)) {
        continue;
    }
    const page = readFileSync(path, 'utf8');
    let before = '';
    try {
        before = git('show', `${reviewed}:core/crates/pe-html/src/help.${language}.html`);
    } catch {
        // a help page the review did not have: every line of it is new
    }
    const known = new Set(before.split('\n').map(l => l.trim()));
    let inside = false;
    let passage = [];
    page.split('\n').forEach((line, index) => {
        const opens = line.includes(REVIEW_START);
        const closes = line.includes(REVIEW_END);
        if (opens) {
            inside = true;
            passage = [];
        }
        const bare = line.replace(REVIEW_START, '').replace(REVIEW_END, '').trim();
        if (inside && bare) {
            passage.push(bare);
        }
        if (!inside && bare && !known.has(bare)) {
            helpUnmarked.push({ language, line: index + 1, text: bare });
        }
        if (closes) {
            inside = false;
            helpWaiting.push({ language, text: passage.join('\n') });
        }
    });
}

function escape(text) {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

if (checking) {
    for (const u of unmarked) {
        console.error(`${u.language}/${u.file}: ${u.id} is ${u.kind} since ${reviewed} but has no "# review: ${u.kind}" mark`);
    }
    for (const u of helpUnmarked) {
        console.error(`help.${u.language}.html:${u.line}: new since ${reviewed} outside <!--review--> marks: ${u.text.slice(0, 80)}`);
    }
    const bad = unmarked.length + helpUnmarked.length;
    console.log(`${waiting.length} messages and ${helpWaiting.length} help passages wait for a review; ${bad} new or changed without a mark`);
    process.exit(bad ? 1 : 0);
}

if (htmlOut) {
    const rows = waiting
        .map(
            w =>
                `<tr><td>${w.language}</td><td>${escape(w.file)}</td><td><code>${escape(w.id)}</code><br><small>${escape(w.mark)}</small></td><td>${escape(
                    w.english
                ).replace(/\n/g, '<br>')}</td><td>${escape(w.draft).replace(/\n/g, '<br>')}</td></tr>`
        )
        .join('\n');
    const help = helpWaiting.map(h => `<tr><td>${h.language}</td><td colspan="4">${escape(h.text).replace(/\n/g, '<br>')}</td></tr>`).join('\n');
    writeFileSync(
        htmlOut,
        `<!doctype html><meta charset="utf-8"><title>Translations to review</title>
<style>body{font:14px system-ui,sans-serif;margin:24px}table{border-collapse:collapse;width:100%}td,th{border:1px solid #ccc;padding:6px;vertical-align:top;text-align:left}th{background:#eee}</style>
<h1>Translations to review</h1><p>Since ${reviewed}: ${waiting.length} messages, ${helpWaiting.length} help passages.</p>
<table><tr><th>Language</th><th>File</th><th>Id</th><th>English</th><th>Draft</th></tr>${rows}</table>
<h2>Help passages</h2><table><tr><th>Language</th><th colspan="4">Passage</th></tr>${help}</table>`
    );
    console.log(`wrote ${htmlOut}`);
} else {
    for (const language of languages) {
        const mine = waiting.filter(w => w.language === language);
        const pages = helpWaiting.filter(h => h.language === language);
        if (!mine.length && !pages.length) {
            continue;
        }
        console.log(`\n${language}: ${mine.length} messages, ${pages.length} help passages`);
        for (const w of mine) {
            console.log(`  ${w.file} ${w.id} (${w.mark})\n    en: ${w.english.replace(/\n/g, ' ')}\n    ${language}: ${w.draft.replace(/\n/g, ' ')}`);
        }
        for (const h of pages) {
            console.log(`  help: ${h.text.replace(/\n/g, ' ').slice(0, 160)}`);
        }
    }
    if (unmarked.length || helpUnmarked.length) {
        console.log(`\n${unmarked.length + helpUnmarked.length} new or changed without a mark: run with --check for the list`);
    }
}
