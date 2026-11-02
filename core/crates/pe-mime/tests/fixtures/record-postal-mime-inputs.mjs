// Records every message postal-mime's own test suite parses (postal-mime-test.ts and its edge
// case tests), so the Rust port can be checked on the same inputs: PostalMime.prototype.parse is
// wrapped before the test files load, and the inputs are written to recorded-inputs.json when the
// tests are done. Run from this directory with postal-mime next to this repository:
//
//     node --experimental-strip-types record-postal-mime-inputs.mjs [path to postal-mime]

import { writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const postalMime = resolve(process.argv[2] || resolve(here, '../../../../../../postal-mime'));
const { default: PostalMime } = await import(pathToFileURL(resolve(postalMime, 'src/postal-mime.ts')).href);

const inputs = new Map();
const original = PostalMime.prototype.parse;
PostalMime.prototype.parse = async function (input) {
    // only top level parses with the default options, nested messages are parsed with options
    if (!this.rfc822NestingDepth && typeof input === 'string' && !Object.keys(this.options || {}).length) {
        inputs.set(input, true);
    } else if (!this.rfc822NestingDepth && input instanceof ArrayBuffer && !Object.keys(this.options || {}).length) {
        inputs.set(Buffer.from(input).toString('latin1'), true);
    }
    return original.call(this, input);
};

process.on('exit', () => {
    const list = [...inputs.keys()].filter(input => input.length < 200_000);
    writeFileSync(resolve(here, 'recorded-inputs.json'), JSON.stringify(list.map(input => Buffer.from(input, 'latin1').toString('base64'))));
    console.error(`recorded ${list.length} messages`);
});

for (const file of ['postal-mime-test.ts', 'postal-mime-edge-cases-test.ts', 'header-parsing-test.ts', 'mime-node-test.ts']) {
    await import(pathToFileURL(resolve(postalMime, 'test', file)).href);
}
