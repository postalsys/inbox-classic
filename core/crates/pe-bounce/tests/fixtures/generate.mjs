// Writes classify-cases.json and detect-cases.json, what the JavaScript originals make of the
// inputs the Rust port is checked against (tests/conformance.rs):
//
// - classify-cases.json: bounce-classifier's classify() and its helpers over every string literal
//   of its own test suite (test/index.test.ts) and a few inputs of ours that exercise the tokenizer
// - detect-cases.json: EmailEngine's bounceDetect() over its bounce fixtures (copied to bounces/)
//   and the bounces its tests build inline
//
// Run with built checkouts (npm run build in bounce-classifier; EmailEngine needs npm install):
//
//     node generate.mjs [path to bounce-classifier] [path to emailengine]

import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const classifierRoot = resolve(process.argv[2] || resolve(here, '../../../../../../bounce-classifier'));
const emailengineRoot = resolve(process.argv[3] || resolve(here, '../../../../../../emailengine'));

const classifier = await import(pathToFileURL(join(classifierRoot, 'dist/esm/index.js')).href);
const require = createRequire(join(emailengineRoot, 'package.json'));
const { bounceDetect } = require(join(emailengineRoot, 'lib/bounce-detect.js'));
const libmime = require('libmime');

// The single quoted string literals of the classifier's test suite, test names left out
function testStrings() {
    const source = readFileSync(join(classifierRoot, 'test/index.test.ts'), 'utf8');
    const strings = new Set();
    const literal = /(\b(?:it|describe)\(\s*)?'((?:[^'\\\n]|\\.)*)'/g;
    for (const m of source.matchAll(literal)) {
        if (m[1]) {
            continue;
        }
        const value = JSON.parse('"' + m[2].replace(/\\'/g, "'").replace(/"/g, '\\"') + '"');
        if (value.trim().length >= 3 && !/^\.{0,2}\//.test(value) && !/^node:/.test(value)) {
            strings.add(value);
        }
    }
    return [...strings];
}

// Inputs for what the test suite does not cover: non-ASCII letters and spaces (JS \w is ASCII,
// \s is not), the length caps, and IP addresses next to status codes
const EXTRA_CLASSIFY = [
    '550 Usuario desconocido: el buzón no existe',
    '550 5.1.1 Benutzer unbekannt, Postfach nicht verfügbar',
    '550 5.1.1 user unknown',
    '﻿550 5.1.1 user unknown',
    '550 5.1.1 user\u0085unknown',
    '550 Kelvin ſpam blocked',
    '554 5.7.1 Message rejected: blocked by İnvaluement',
    '421 4.7.0 [192.0.2.1] Try again in 15 minutes, greylisted',
    '450 4.2.0 Greylisted, please come back in 5 min',
    '550 5.7.1 Service unavailable; client [203.0.113.9] blocked using zen.spamhaus.org and b.barracudacentral.org',
    '554 5.7.1 Rejected: listed in cloudmark reputation and proofpoint block list',
    '550-5.7.26 Unauthenticated email from example.com is not accepted due to domain’s DMARC policy',
    'smtp; 550 5.1.1 <user@example.com>... User unknown',
    '552 5.2.2 Mailbox full ' + 'quota '.repeat(150),
    ('x'.repeat(9990) + ' user unknown').slice(0),
    '日本語 550 5.1.1 宛先不明',
    'Error: connection timed out after 30 seconds, will retry after 2 hours',
    '5.2.1 The email account that you tried to reach is disabled.',
    '550 No such user here'
];

function classifyCase(message) {
    const out = { message };
    out.retryAfter = classifier.extractRetryTiming(message);
    out.blocklist = classifier.identifyBlocklist(message);
    out.smtpCodes = classifier.extractSmtpCodes(message);
    out.textFallback = classifier.getTextBasedFallback(message);
    out.codeFallback = classifier.getCodeBasedFallback(message);
    return out;
}

async function classifyCases() {
    await classifier.initialize();
    const cases = [];
    for (const message of [...testStrings(), ...EXTRA_CLASSIFY]) {
        const out = classifyCase(message);
        if (message.trim()) {
            out.result = await classifier.classify(message);
        }
        cases.push(out);
    }
    return cases;
}

// bounce-heuristics-test.js builds its bounces like this
function buildBounce(headers, body) {
    const lines = [
        'From: Mail Delivery System <mailer-daemon@mta.example.com>',
        'To: sender@example.com',
        'Subject: Mail delivery failed',
        'Date: Wed, 01 Jan 2025 00:00:00 +0000',
        'MIME-Version: 1.0'
    ];
    for (const [key, value] of Object.entries(headers || {})) {
        lines.push(`${key}: ${value}`);
    }
    lines.push('Content-Type: text/plain; charset=utf-8');
    lines.push('');
    lines.push(body);
    return lines.join('\r\n');
}

// The bounce bounce-test.js builds with extra headers in the attached message
function bounceWithOriginalHeaders(extraHeaders) {
    return [
        'From: mailer-daemon@example.com',
        'To: sender@example.com',
        'Subject: Undelivered Mail Returned to Sender',
        'Content-Type: multipart/report; report-type=delivery-status; boundary="B"',
        'MIME-Version: 1.0',
        '',
        '--B',
        'Content-Type: text/plain',
        '',
        'delivery failed',
        '',
        '--B',
        'Content-Type: message/delivery-status',
        '',
        'Reporting-MTA: dns; mx.example.com',
        '',
        'Final-Recipient: rfc822; bob@example.com',
        'Action: failed',
        'Status: 5.1.1',
        '',
        '--B',
        'Content-Type: message/rfc822',
        '',
        'Subject: original subject'
    ]
        .concat(extraHeaders)
        .concat(['Message-ID: <orig@example.com>', 'From: sender@example.com', 'To: bob@example.com', '', 'original body', '', '--B--', ''])
        .join('\r\n');
}

const INLINE_BOUNCES = {
    'postfix-host-said': buildBounce(
        {},
        ['<bob@example.com>: host mx.example.com[203.0.113.4] said: 550 5.1.1 No such user here', '(in reply to RCPT TO command)', ''].join('\r\n')
    ),
    'x-failed-recipients': buildBounce({ 'X-Failed-Recipients': 'carol@example.com' }, 'Your message could not be delivered.'),
    'x-failed-recipients-several': buildBounce({ 'X-Failed-Recipients': 'first@example.com, second@example.com' }, 'Delivery problem.'),
    'google-legacy': buildBounce(
        {},
        [
            'Delivery to the following recipient failed permanently:',
            '',
            '     dave@example.com',
            '',
            'Technical details of permanent failure:',
            'Google tried to deliver your message, but it was rejected by the recipient domain.',
            ''
        ].join('\r\n')
    ),
    'recipient-block': buildBounce(
        {},
        [
            'Sorry, we were unable to deliver your message to the following address.',
            '',
            '<erin@example.com>:',
            '550: 5.1.1 <erin@example.com>: Recipient address rejected: User unknown in relay recipient table',
            ''
        ].join('\r\n')
    ),
    'bare-status-line': buildBounce({}, ['Technical details of permanent failure:', '', '550 5.7.1 Message rejected due to content policy', ''].join('\r\n')),
    'warning-message-only': buildBounce(
        {},
        [
            'Hi. This is the mail delivery program at mail.example.com.',
            "I'm afraid I wasn't able to deliver your message to the following addresses yet.",
            'THIS IS A WARNING MESSAGE ONLY.',
            'YOU DO NOT NEED TO RESEND YOUR MESSAGE.',
            '',
            '<frank@example.com>:',
            "Sorry, I wasn't able to establish an SMTP connection. (#4.4.1)",
            "I'll keep trying for a while longer.",
            ''
        ].join('\r\n')
    ),
    'quoted-4xx-said': buildBounce(
        {},
        ['<grace@example.com>: host mx.example.com[203.0.113.4] said: 450 4.2.1 Mailbox temporarily unavailable', '(in reply to RCPT TO command)', ''].join(
            '\r\n'
        )
    ),
    'qmail-gave-up': buildBounce(
        {},
        [
            'Hi. This is the qmail-send program at mail.example.com.',
            "I'm afraid I wasn't able to deliver your message to the following addresses.",
            "This is a permanent error; I've given up. Sorry it didn't work out.",
            '',
            '<heidi@example.com>:',
            "Sorry, I wasn't able to establish an SMTP connection. (#4.4.1)",
            "I'm not going to try again; this message has been in the queue too long.",
            ''
        ].join('\r\n')
    ),
    'undeliverable-to': buildBounce({}, 'The following message to <ivan@example.com> was undeliverable.\r\nThe reason for the problem: user unknown\r\n'),
    'remote-host-said': buildBounce(
        {},
        'Your message could not be delivered to the following address: <judy@example.com>\r\n\r\nRemote host said: 550 No such user\r\n'
    ),
    'reason-for-problem': buildBounce(
        {},
        "The following message to <kim@example.com> was undeliverable.\r\nThe reason for the problem:\r\n5.1.0 - Unknown address error 550-'kim@example.com... No such user'\r\n"
    ),
    'exim-failed-addresses': buildBounce(
        { 'X-Failed-Recipients': 'info@example.com' },
        [
            'This message was created automatically by mail delivery software.',
            '',
            'A message that you sent could not be delivered to one or more of its',
            'recipients. This is a permanent error. The following address(es) failed:',
            '',
            '  info@example.com',
            '    Domain example.org has exceeded the max defers and failures per hour (5/5 (100%)) allowed. Message discarded.',
            ''
        ].join('\r\n')
    ),
    'kddi-could-not-be-delivered': buildBounce({}, 'Could not be delivered to: <kijitora@example.com>\r\nAs their mailbox is full.\r\n'),
    'permanent-errors': buildBounce({}, 'The following recipients returned permanent errors: kijitora@example.com\r\n'),
    'carrier-error': buildBounce({}, 'Message could not be delivered to mobile.\r\nError: No valid recipients for this MM\r\n'),
    'rcpt-to': buildBounce({}, 'RCPT TO: 000000000000@example.com\r\n550 - Requested action not taken: no such user here\r\n'),
    'affected-recipients': buildBounce({}, 'The following recipients were affected:\r\n    lee@example.com\r\n\r\n550 5.1.1 user unknown\r\n'),
    'host-said-no-brackets': buildBounce({}, '<bob@example.com>: host mx.example.com said: 550 5.1.1 No such user here\n'),
    'leading-reply-hyphen': buildBounce({}, 'Technical details:\n\n550-5.7.1 [1.2.3.4 11] Message rejected\n'),
    'embedded-headers': buildBounce(
        {},
        [
            '<mia@example.com>: host mx.example.com[203.0.113.4] said: 550 5.1.1 No such user',
            '',
            '--- Below this line is a copy of the message.',
            '',
            'Return-Path: <sender@example.com>',
            'Received: from mail.example.com by mx.example.com',
            'Message-ID: <embedded@example.com>',
            'Subject: Embedded',
            'To: mia@example.com',
            '',
            'body'
        ].join('\r\n')
    ),
    'original-headers-prototype-names': bounceWithOriginalHeaders(['__proto__: injected', 'constructor: c']),
    'original-headers-clean': bounceWithOriginalHeaders([]),
    'dsn-several-recipients': [
        'From: Mail Delivery System <MAILER-DAEMON@mx.example.com>',
        'To: sender@example.com',
        'Subject: Undelivered Mail Returned to Sender',
        'MIME-Version: 1.0',
        'Content-Type: multipart/report; report-type=delivery-status; boundary="B"',
        '',
        '--B',
        'Content-Type: text/plain',
        '',
        'Two recipients failed.',
        '--B',
        'Content-Type: message/delivery-status',
        '',
        'Reporting-MTA: dns; MX.Example.com',
        '',
        'Final-Recipient: rfc822; first@example.com',
        'Action: failed',
        'Status: 5.1.1',
        'Remote-MTA: dns; mx.first.example',
        'Diagnostic-Code: smtp; 550 5.1.1 <first@example.com>: Recipient address',
        '    rejected: User unknown',
        '',
        'Final-Recipient: rfc822; second@example.com',
        'Action: failed',
        'Status: 5.2.2',
        'Diagnostic-Code: smtp; 552 5.2.2 Mailbox full',
        '--B',
        'Content-Type: text/rfc822-headers',
        '',
        'Message-ID: <two@example.com>',
        'Subject: =?UTF-8?Q?Tere_=C3=B5htust?=',
        'Date: Wed, 01 Jan 2025 00:00:00 +0000',
        'To: first@example.com, second@example.com',
        '--B--',
        ''
    ].join('\r\n')
};

function normalizeHeaders(headers) {
    if (!headers) {
        return null;
    }
    const out = {};
    for (const key of Object.keys(headers)) {
        out[key] = headers[key].map(value => String(value).replace(/\r\n|\r/g, '\n'));
    }
    return out;
}

function firstDecoded(headers, key) {
    const values = headers && headers[key];
    if (!values || !values.length) {
        return null;
    }
    return libmime.decodeWords(
        String(values[0])
            .replace(/\r?\n[ \t]*/g, ' ')
            .trim()
    );
}

async function detectCase(name, raw) {
    const bounce = await bounceDetect(Buffer.from(raw));
    const out = {
        name,
        recipient: bounce.recipient ?? null,
        action: bounce.action ?? null,
        response: bounce.response ?? null,
        mta: bounce.mta ?? null,
        queueId: bounce.queueId ?? null,
        messageId: bounce.messageId ?? null,
        messageHeaders: normalizeHeaders(bounce.messageHeaders),
        original: {
            subject: firstDecoded(bounce.messageHeaders, 'subject'),
            date: firstDecoded(bounce.messageHeaders, 'date'),
            to: firstDecoded(bounce.messageHeaders, 'to')
        }
    };
    if (bounce.response && bounce.response.message) {
        out.classification = await classifier.classify(bounce.response.message);
    }
    return out;
}

async function detectCases() {
    const cases = [];
    const dir = join(here, 'bounces');
    for (const file of readdirSync(dir)
        .filter(f => f.endsWith('.eml'))
        .sort()) {
        const out = await detectCase(file, readFileSync(join(dir, file)));
        out.file = file;
        cases.push(out);
    }
    for (const [name, raw] of Object.entries(INLINE_BOUNCES)) {
        const out = await detectCase(name, raw);
        out.raw = raw;
        cases.push(out);
    }
    return cases;
}

const classify = await classifyCases();
writeFileSync(join(here, 'classify-cases.json'), JSON.stringify(classify, null, 1) + '\n');
const detect = await detectCases();
writeFileSync(join(here, 'detect-cases.json'), JSON.stringify(detect, null, 1) + '\n');
console.log(`${classify.length} classifier cases, ${detect.length} bounces`);
