// Writes cases.json, what otp-detect makes of the inputs the Rust port is checked against
// (tests/conformance.rs): for every message, each candidate occurrence with its feature vector and
// score, scoreCandidates() and detectOtp().
//
// The inputs are inputs.json (otp-detect's own test inputs and hand-written synthetic emails; never
// real mail) and random messages built here from a fixed seed out of markup, entities, keywords,
// codes and non-ASCII text, so the renderer and the features meet what no one would write by hand.
//
// Run with a built otp-detect checkout (npm run build there):
//
//     node generate.mjs [path to otp-detect]

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(process.argv[2] || resolve(here, '../../../../../../otp-detect'));
const load = name => import(pathToFileURL(join(root, 'dist/esm', name)).href);

const { analyze } = await load('analyze.js');
const { predict } = await load('model.js');
const { MODEL } = await load('model-data.js');
const { detectOtp, scoreCandidates } = await load('index.js');
const { FEATURE_NAMES } = await load('features.js');

// A small xorshift generator, so the random inputs are the same on every run
let state = 0x9e3779b9;
function next() {
    state ^= state << 13;
    state >>>= 0;
    state ^= state >>> 17;
    state ^= state << 5;
    state >>>= 0;
    return state;
}
const pick = list => list[next() % list.length];

const PIECES = [
    // markup
    '<p>',
    '</p>',
    '<div>',
    '</div>',
    '<br>',
    '<td>',
    '</td>',
    '<tr>',
    '<table>',
    '</table>',
    '<b>',
    '</b>',
    '<strong>',
    '<h1>',
    '</h1>',
    '<h3>',
    '<span style="font-size:28px;letter-spacing:4px">',
    '</span>',
    '<span style="display:none">',
    '<a href="https://example.com/x">',
    '</a>',
    '<a>',
    '<code>',
    '</code>',
    '<font size="5">',
    '</font>',
    '<blockquote>',
    '</blockquote>',
    '<div class="gmail_quote">',
    '<style>',
    '</style>',
    '<!-- c -->',
    '<!doctype html>',
    '<img src="x.png"/>',
    '<hr>',
    '<p style="font-size:2em">',
    '<p style="font-weight:bold;font-family:monospace">',
    '<x y="a>b">',
    "<x y='<'>",
    '<',
    '>',
    '</',
    '<p/>',
    // entities
    '&amp;',
    '&nbsp;',
    '&#52;',
    '&#x35;',
    '&euro;',
    '&uuml;',
    '&bogus;',
    '&#0;',
    '&#128512;',
    '&',
    '&shy;',
    // words
    'Your code is',
    'verification code',
    'security code:',
    'one-time password',
    'kinnituskood',
    'Bestätigungscode',
    'código de verificación',
    'код подтверждения',
    '验证码',
    'order',
    'invoice',
    'Tracking',
    'promo code',
    'gift card',
    'save 20% off',
    'expires in 10 minutes',
    'do not share',
    'enter',
    'PIN',
    'token',
    'Total:',
    'phone',
    'On Mon, 1 Jan 2026 Anna wrote:',
    '-----Original Message-----',
    'kirjutas:',
    '> quoted',
    // codes and numbers
    '482917',
    '604 381',
    '12-34-56',
    'K7PX-29QD',
    'QWKZT',
    'AB12CD34',
    '1 2 3 4 5 6',
    '2026',
    '49.90',
    '10:30',
    '+372 555 0100',
    '#731942',
    '$129.00',
    '€42',
    '5000mAh',
    'aZ3kQ9mW2xP7rT5v',
    '000000',
    '123456',
    'WEBINAR',
    // space and non-ASCII
    ' ',
    ' ',
    ' ',
    '\n',
    '\r\n',
    '\t',
    ' ',
    '​',
    ' ',
    '﻿',
    'ä',
    'ſ',
    'K',
    '😀',
    '𝟒𝟓',
    'İ',
    'Σ',
    '日本',
    '́'
];

function randomMessage(i) {
    const parts = [];
    const count = 20 + (next() % 200);
    for (let j = 0; j < count; j++) {
        parts.push(pick(PIECES));
    }
    const body = parts.join(next() % 3 === 0 ? '' : ' ');
    const subject = next() % 2 ? pick(PIECES) + ' ' + pick(PIECES) : undefined;
    switch (i % 3) {
        case 0:
            return { name: `random ${i}`, subject, html: body };
        case 1:
            return { name: `random ${i}`, subject, text: body };
        default:
            return { name: `random ${i}`, subject, html: body, text: parts.slice(0, count / 2).join('\n') };
    }
}

const inputs = JSON.parse(readFileSync(join(here, 'inputs.json'), 'utf8'));
for (let i = 0; i < 45; i++) {
    inputs.push(randomMessage(i));
}

const git = args => {
    try {
        return execFileSync('git', ['-C', root, ...args], { encoding: 'utf8' }).trim();
    } catch {
        return 'unknown';
    }
};

const cases = inputs.map(({ name, ...input }) => {
    const occurrences = analyze(input).map(o => ({
        code: o.candidate.code,
        raw: o.candidate.raw,
        kind: o.candidate.kind,
        source: o.source,
        // NaN (a font size otp-detect cannot read) is written as null
        features: o.features,
        score: predict(MODEL, o.features)
    }));
    const answer = detectOtp(input);
    return { name, input, occurrences, candidates: scoreCandidates(input), answer };
});

const out = {
    generator: `otp-detect ${git(['describe', '--tags', '--always', '--dirty'])} (${git(['rev-parse', 'HEAD'])})`,
    featureNames: FEATURE_NAMES,
    threshold: MODEL.threshold,
    cases
};
// One case per line: small, and a changed case shows as one changed line
const { cases: all, ...head } = out;
const lines = JSON.stringify(head).slice(0, -1) + ',\n"cases":[\n' + all.map(c => JSON.stringify(c)).join(',\n') + '\n]}\n';
writeFileSync(join(here, 'cases.json'), lines);
console.log(`${cases.length} cases, ${cases.reduce((n, c) => n + c.occurrences.length, 0)} occurrences`);
