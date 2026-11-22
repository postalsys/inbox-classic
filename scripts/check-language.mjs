#!/usr/bin/env node
// Checks one language's catalogs and help against English before the language is registered in pe-i18n:
//   node scripts/check-language.mjs <code>
// The same messages as English in each file (none missing, none extra, none twice), each with the placeables English
// has, a default variant in every selector, a review mark above every message, no en or em dashes; every help topic
// English has, inside review marks, with the same data-text words, topic links and pictures as English.
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const code = process.argv[2];
if (!code || code === 'en') {
    console.error('usage: node scripts/check-language.mjs <code>');
    process.exit(2);
}
const problems = [];
const problem = (where, what) => problems.push(`${where}: ${what}`);

// the messages of a Fluent file: id, its whole text (value and attributes), and whether a review mark is above it
function messages(text) {
    const lines = text.split('\n');
    const found = [];
    let current = null;
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const start = /^([a-zA-Z][a-zA-Z0-9_-]*)\s*=/.exec(line);
        if (start) {
            let k = i - 1;
            while (k >= 0 && lines[k].startsWith('#') && !lines[k].startsWith('# review')) k--;
            const marked = k >= 0 && /^# review: (new|changed)/.test(lines[k]);
            current = { id: start[1], text: line, marked, line: i + 1 };
            found.push(current);
        } else if (current && (line.startsWith(' ') || line.startsWith('\t') || line.startsWith('}') || line.trim() === '')) {
            // a selector's closing brace may start a line, with more of the message after it ("}, { $unread } unread")
            if (line.trim() !== '') current.text += '\n' + line;
        } else {
            current = null;
        }
    }
    return found;
}

// Japanese and Chinese: the sentence has no spaces, so none around a placeable either; one kind of each punctuation
// mark in a message (full width as the language writes it, or ASCII), and the access key a Latin letter in brackets
// after the words (ファイル(&F)), as their Windows has it. Korean writes spaces and ASCII punctuation, so only the access
// key rule is its.
const CJK = ['ja', 'zh-Hans', 'zh-Hant', 'ko'].includes(code);
const SPACELESS = ['ja', 'zh-Hans', 'zh-Hant'].includes(code);
const ideograph = '\\p{Script=Han}\\p{Script=Hiragana}\\p{Script=Katakana}';
const PAIRS = [['，', ','], ['：', ':'], ['；', ';'], ['！', '!'], ['？', '?'], ['（', '(']];
function cjkProblems(m) {
    const found = [];
    // the value and attributes alone: no id, no placeables, no access key, no links or command line options
    const text = m.text
        .replace(/^[^=]*=/, '')
        .replace(/^\s*\.[a-z-]+\s*=/gm, '')
        .replace(/\(&[A-Za-z0-9]\)/g, '')
        .replace(/https?:\/\/\S+/g, '');
    if (/&[^&\sA-Za-z0-9]/u.test(text.replace(/&&/g, ''))) found.push('marks a non-Latin access key: write it as (&F) after the words');
    if (!SPACELESS) return found;
    if (new RegExp(`[${ideograph}] \\{|\\} [${ideograph}]`, 'u').test(text)) found.push('has a space between a placeable and the words around it');
    const plain = text.replace(/\{[^{}]*\}/g, '').replace(/\[[a-z]+\]|\*\[[a-z]+\]/g, '');
    for (const [wide, ascii] of PAIRS) {
        if (plain.includes(wide) && plain.includes(ascii)) found.push(`mixes ${wide} and ${ascii}`);
    }
    return found;
}

const variables = (text) => new Set([...text.matchAll(/\$([a-zA-Z][a-zA-Z0-9_-]*)/g)].map((m) => m[1]));
const same = (a, b) => a.size === b.size && [...a].every((x) => b.has(x));

const english = join(root, 'core/locales/en');
for (const file of readdirSync(english).filter((f) => f.endsWith('.ftl'))) {
    const where = `core/locales/${code}/${file}`;
    const path = join(root, where);
    if (!existsSync(path)) {
        problem(where, 'missing');
        continue;
    }
    const text = readFileSync(path, 'utf8');
    if (/[–—]/.test(text)) problem(where, 'an en or em dash');
    const en = new Map(messages(readFileSync(join(english, file), 'utf8')).map((m) => [m.id, m]));
    const seen = new Set();
    for (const m of messages(text)) {
        if (seen.has(m.id)) problem(`${where}:${m.line}`, `${m.id} is there twice`);
        seen.add(m.id);
        const source = en.get(m.id);
        if (!source) {
            problem(`${where}:${m.line}`, `${m.id} is not in English`);
            continue;
        }
        if (!same(variables(m.text), variables(source.text))) {
            problem(`${where}:${m.line}`, `${m.id} uses {${[...variables(m.text)]}} where English uses {${[...variables(source.text)]}}`);
        }
        if (m.text.includes('->') && !/\*\[/.test(m.text)) problem(`${where}:${m.line}`, `${m.id} has a selector without a *[default]`);
        if (!m.marked) problem(`${where}:${m.line}`, `${m.id} has no "# review: new" above it`);
        // an access key (&) where English has one, so menus keep their keys
        if (/&[^&\s]/.test(source.text.replace(/&&/g, '')) && !/&[^&\s]/.test(m.text.replace(/&&/g, ''))) {
            problem(`${where}:${m.line}`, `${m.id} has no access key (&) where English has one`);
        }
        if (CJK) cjkProblems(m).forEach((what) => problem(`${where}:${m.line}`, `${m.id} ${what}`));
    }
    for (const id of en.keys()) if (!seen.has(id)) problem(where, `${id} is missing`);
}

// help: every topic, inside review marks, the same words, links and pictures as English
const help = join(root, 'core/crates/pe-html/help');
const refs = (text, pattern) => new Set([...text.matchAll(pattern)].map((m) => m[1]));
for (const file of readdirSync(join(help, 'en')).filter((f) => f.endsWith('.html'))) {
    const where = `core/crates/pe-html/help/${code}/${file}`;
    const path = join(root, where);
    if (!existsSync(path)) {
        problem(where, 'missing');
        continue;
    }
    const text = readFileSync(path, 'utf8');
    const en = readFileSync(join(help, 'en', file), 'utf8');
    if (/[–—]/.test(text)) problem(where, 'an en or em dash');
    if (!text.trimStart().startsWith('<!--review-->') || !text.trimEnd().endsWith('<!--/review-->')) {
        problem(where, 'not wholly inside <!--review--> ... <!--/review-->');
    }
    for (const [name, pattern] of [
        ['data-text', /data-text="([^"]+)"/g],
        ['topic link', /href="topic:([^"]+)"/g],
        ['picture', /src="picture:([^"]+)"/g],
        ['os part', /<!--os:([a-z,]+)-->/g],
    ]) {
        const mine = refs(text, pattern);
        const theirs = refs(en, pattern);
        for (const x of theirs) if (!mine.has(x)) problem(where, `the ${name} "${x}" of English is missing`);
        for (const x of mine) if (!theirs.has(x)) problem(where, `a ${name} "${x}" English does not have`);
    }
    const count = (t, s) => t.split(s).length - 1;
    for (const tag of ['<h1>', '<h2>', '<li>', '<kbd>', '<aside']) {
        if (count(text, tag) !== count(en, tag)) problem(where, `${count(text, tag)} ${tag} where English has ${count(en, tag)}`);
    }
}

if (problems.length) {
    console.log(problems.join('\n'));
    console.log(`${problems.length} problems in ${code}`);
    // not process.exit: a long list written into a pipe would be cut off
    process.exitCode = 1;
} else {
    console.log(`${code}: every catalog and help topic matches English`);
}
