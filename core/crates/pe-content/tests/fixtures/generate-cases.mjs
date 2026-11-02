// Writes cases.json: what email-content's analyze() makes of the bodies its own tests analyze
// (recorded-inputs.json, made by record-inputs.mjs) and of every .eml fixture in its test/
// directory. A fixture is turned into body sections exactly the way extract() does it (MIME parse,
// body plan, one section per planned section), so the Rust port, which leaves MIME to pe-mime, can
// be fed the same sections. tests/conformance.rs checks the port against the result. Run with a
// built email-content (npm run build there):
//
//     node generate-cases.mjs [path to email-content]

import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve, dirname, relative, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(process.argv[2] || resolve(here, '../../../../../../email-content'));
const require = createRequire(resolve(root, 'package.json'));
const { analyze, parseMessage, planBody, DEFAULT_CONFIDENCE } = require(resolve(root, 'dist/index.js'));

/** The parts buildHistoryDocument() reads from a raw message, in its order. */
async function historyParts(raw) {
    const message = await parseMessage(Buffer.isBuffer(raw) ? raw : Buffer.from(raw));
    const parts = [];
    for (const part of message.parts) {
        if (!part.decoded || part.disposition === 'attachment') {
            continue;
        }
        if (part.contentType === 'text/plain') {
            parts.push({ representation: 'text', body: part.decoded.text });
        } else if (part.contentType === 'text/html') {
            parts.push({ representation: 'html', body: part.decoded.text });
        }
    }
    return { parts };
}

/** The input analyze() is called with, and the same input in the form the Rust test reads. */
async function prepare(record) {
    const options = { ...record.options };
    const replay = { ...record.options };
    if (record.options.history) {
        options.history = [];
        replay.history = [];
        for (const item of record.options.history) {
            if (typeof item === 'string' || (item && item.raw)) {
                const raw = typeof item === 'string' ? Buffer.from(item) : Buffer.from(item.raw, 'base64');
                options.history.push(raw);
                replay.history.push(await historyParts(raw));
            } else {
                options.history.push(item);
                replay.history.push(item);
            }
        }
    }
    return { options, replay };
}

/** Sections exactly as extract() builds them from a raw message. */
async function sectionsOf(raw) {
    const message = await parseMessage(raw);
    const plan = planBody(message);
    return {
        sections: plan.sections.map(section => ({
            text: section.text?.decoded?.text ?? null,
            html: section.html?.decoded?.text ?? null,
            ...(section.text ? { textPartId: section.text.partId } : {}),
            ...(section.html ? { htmlPartId: section.html.partId } : {}),
            role: section.role
        })),
        subject: message.headers.subject,
        from: message.headers.from,
        inReplyTo: message.headers.inReplyTo,
        references: message.headers.references
    };
}

function emlFiles(dir) {
    const out = [];
    for (const name of readdirSync(dir).sort()) {
        const path = join(dir, name);
        if (statSync(path).isDirectory()) {
            out.push(...emlFiles(path));
        } else if (name.endsWith('.eml')) {
            out.push(path);
        }
    }
    return out;
}

const records = [];
const seen = new Set();
const add = (name, record) => {
    // extract() always passes its validated thresholds; the defaults are the same as none.
    if (JSON.stringify(record.options.confidence) === JSON.stringify(DEFAULT_CONFIDENCE)) {
        const { confidence: _defaults, ...options } = record.options;
        record = { ...record, options };
    }
    const key = JSON.stringify(record);
    if (!seen.has(key)) {
        seen.add(key);
        records.push({ name, ...record });
    }
};

const recorded = JSON.parse(readFileSync(resolve(here, 'recorded-inputs.json'), 'utf8'));
recorded.forEach((record, i) => add(`recorded-${i}`, record));

const fixtureDir = resolve(root, 'test/fixtures');
for (const path of emlFiles(fixtureDir)) {
    add(relative(fixtureDir, path), { content: await sectionsOf(readFileSync(path)), options: {} });
}

const cases = [];
for (const record of records) {
    const { options, replay } = await prepare(record);
    let expected;
    try {
        const result = await analyze(record.content, options);
        delete result.diagnostics;
        expected = result;
    } catch (err) {
        expected = { error: err.code || String(err), option: err.option };
    }
    cases.push({ name: record.name, content: record.content, options: replay, expected });
}

writeFileSync(resolve(here, 'cases.json'), JSON.stringify(cases));
console.error(`wrote ${cases.length} cases`);
