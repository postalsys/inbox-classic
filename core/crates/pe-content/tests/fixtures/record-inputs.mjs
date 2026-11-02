// Records every analyze() call email-content's own test suite makes (directly, or through
// extract()), so the Rust port can be checked on the same inputs: analyze is wrapped in the
// compiled test build before the test files load, and the inputs are written to
// recorded-inputs.json when the tests are done. Build the tests first, then run from anywhere:
//
//     (cd ../email-content && npm run build:test)
//     node record-inputs.mjs [path to email-content]

import { writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(process.argv[2] || resolve(here, '../../../../../../email-content'));
const require = createRequire(resolve(root, 'package.json'));
const analyzeModule = require(resolve(root, '.build-test/src/analyze.js'));

// Inputs larger than this are left to the hand written adversarial tests, so the committed JSON
// stays small.
const MAX_INPUT = 200_000;

const inputs = new Map();

function plain(value) {
    if (value === null || value === undefined) {
        return value ?? null;
    }
    if (Buffer.isBuffer(value)) {
        return { raw: value.toString('base64') };
    }
    return value;
}

function sizeOf(content) {
    let size = 0;
    for (const section of content.sections ?? [content]) {
        size += (section.text?.length ?? 0) + (section.html?.length ?? 0);
    }
    return size;
}

const original = analyzeModule.analyze;
analyzeModule.analyze = async function (content, options = {}) {
    try {
        // Pre-built history documents and pattern overrides cannot be replayed from JSON.
        if (!options.historyDocuments && !process.env.EMAIL_CONTENT_PATTERNS && content && sizeOf(content) < MAX_INPUT) {
            const record = {
                content: {
                    ...(content.text !== undefined ? { text: content.text } : {}),
                    ...(content.html !== undefined ? { html: content.html } : {}),
                    ...(content.sections ? { sections: content.sections } : {}),
                    ...(content.subject !== undefined ? { subject: content.subject } : {}),
                    ...(content.from !== undefined ? { from: content.from } : {}),
                    ...(content.inReplyTo !== undefined ? { inReplyTo: content.inReplyTo } : {}),
                    ...(content.references !== undefined ? { references: content.references } : {}),
                    ...(content.textPartId !== undefined ? { textPartId: content.textPartId } : {}),
                    ...(content.htmlPartId !== undefined ? { htmlPartId: content.htmlPartId } : {})
                },
                options: {
                    ...(options.confidence ? { confidence: options.confidence } : {}),
                    ...(options.maxContentChars !== undefined ? { maxContentChars: options.maxContentChars } : {}),
                    ...(options.history ? { history: options.history.map(plain) } : {})
                }
            };
            const key = JSON.stringify(record);
            if (key.length < MAX_INPUT * 2) {
                inputs.set(key, record);
            }
        }
    } catch {
        // Recording must never change what the tests see.
    }
    return original.call(this, content, options);
};

process.on('exit', () => {
    const list = [...inputs.values()];
    writeFileSync(resolve(here, 'recorded-inputs.json'), JSON.stringify(list));
    console.error(`recorded ${list.length} analyze calls`);
});

for (const file of [
    'analyze',
    'adversarial',
    'body-plan',
    'canonical-text',
    'clients',
    'config',
    'contract',
    'corpus-regressions',
    'degraded-html',
    'extract',
    'match',
    'performance',
    'segment'
]) {
    require(resolve(root, `.build-test/test/${file}.test.js`));
}
