// Writes message-cases.json: what imapflow makes of FETCH responses with ENVELOPE and BODYSTRUCTURE
// (its parser, parseEnvelope and parseBodystructure), and of mailbox names in modified UTF-7
// (iconv-lite's utf-7-imap, as imapflow uses it). tests/message_conformance.rs checks the port.
//
//     node --experimental-strip-types generate-message-cases.mjs [path to imapflow]

import { writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const imapflow = resolve(process.argv[2] || resolve(here, '../../../../../../imapflow'));
const load = path => import(pathToFileURL(resolve(imapflow, path)).href);
const { parser } = await load('dist/esm/handler/imap-handler.js');
const { ImapStream } = await load('dist/esm/handler/imap-stream.js');
const { parseEnvelope, parseBodystructure } = await load('dist/esm/tools.js');
const mimetorture = (await load('test/fixtures/serialized-mimetorture.ts')).default;
const iconv = createRequire(resolve(imapflow, 'package.json'))('iconv-lite');

const fetches = [
    mimetorture.input,
    '* 1 FETCH (ENVELOPE ("Mon, 6 Oct 2025 10:00:00 +0000" "=?UTF-8?Q?Tere_t=C3=A4na?=" (("\\"Andris\\"" NIL "andris" "example.com")) NIL NIL ((NIL NIL "undisclosed-recipients" NIL)(NIL NIL NIL NIL)) NIL NIL NIL "<id@example.com>"))',
    '* 2 FETCH (ENVELOPE (NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL))',
    '* 3 FETCH (ENVELOPE ("" "" ((NIL NIL "a" "b")) ((NIL NIL "group" NIL)(NIL NIL "x" "y.z")(NIL NIL NIL NIL)) NIL NIL NIL NIL " <r@x> " " <m@x> "))',
    '* 4 FETCH (ENVELOPE ("Thu, 23 Oct 2003 23:28:34 -0700 (PDT)" "plain" (("=?ISO-8859-1?Q?J=F5ul?=" NIL "j" "x.ee")) NIL NIL NIL ((NIL NIL "only" "cc.ee")) ((NIL NIL "only" "bcc.ee")) NIL NIL))',
    '* 5 FETCH (BODYSTRUCTURE (("text" "plain" ("charset" "utf-8") NIL NIL "7bit" 12 1 NIL NIL NIL NIL)("application" "pdf" ("name" "=?UTF-8?Q?=C3=B5.pdf?=") NIL NIL "base64" 100 NIL ("attachment" ("filename*" "utf-8\'\'%C3%B5.pdf")) NIL NIL) "mixed" ("boundary" "b1") NIL NIL NIL))',
    '* 6 FETCH (BODYSTRUCTURE ("TEXT" "HTML" ("CHARSET" "ISO-8859-1") "<cid@x>" "desc" "QUOTED-PRINTABLE" 250 10 "ABCDEF" ("INLINE" NIL) ("EN" "ET") "http://x/loc"))',
    '* 7 FETCH (BODYSTRUCTURE ("text" "plain" ("charset" "us-ascii") NIL NIL "7bit" 5 NIL ("inline" ("filename" "a.txt")) NIL))',
    '* 8 FETCH (BODYSTRUCTURE ("text" "plain" NIL NIL NIL "7bit" 5))',
    '* 9 FETCH (BODYSTRUCTURE (("text" "plain" NIL NIL NIL "7bit" 5 1) "alternative"))',
    '* 10 FETCH (BODYSTRUCTURE ("message" "rfc822" NIL NIL NIL "7bit" 300 ("Mon, 6 Oct 2025 10:00:00 +0000" "inner" NIL NIL NIL NIL NIL NIL NIL NIL) ("text" "plain" NIL NIL NIL "7bit" 10 1) 12 NIL NIL NIL NIL))',
    '* 11 FETCH (BODYSTRUCTURE ("image" "png" ("name*0" "very" "name*1" "long.png") "<img1>" NIL "base64" 4096 NIL ("inline" ("filename*0*" "utf-8\'\'%C3%A4" "filename*1" ".png")) "et" NIL))',
    '* 12 FETCH (BODYSTRUCTURE ((("text" "plain" NIL NIL NIL "7bit" 1 1)("text" "html" NIL NIL NIL "7bit" 1 1) "alternative")("image" "gif" NIL NIL NIL "base64" 9) "related" NIL ("inline" NIL) ("de")))'
];

const names = ['INBOX', 'Tom & Jerry', 'Отправленные', '~peter/mail/台北/日本語', 'Šegregator/Społeczności', '😀', 'Sent Items', '&'];

const iso = value => (value instanceof Date ? value.toISOString() : value);
const envelope = env => {
    if (env && env.date) {
        env.date = iso(env.date);
    }
    return env;
};
const structure = node => {
    if (node.envelope) {
        envelope(node.envelope);
    }
    (node.childNodes || []).forEach(structure);
    return node;
};

// framed by ImapStream as on a connection, literals included
const frame = async input => {
    const stream = new ImapStream();
    const items = [];
    stream.on('data', item => {
        items.push(item);
        item.next();
    });
    const done = new Promise((resolve, reject) => stream.on('end', resolve).on('error', reject));
    stream.end(Buffer.from(input + '\r\n'));
    await done;
    return items[0];
};

const cases = { fetches: [], names: [] };
for (const input of fetches) {
    const { payload, literals } = await frame(input);
    const parsed = await parser(payload, { literals });
    const items = parsed.attributes[1];
    const out = { input };
    for (let i = 0; i < items.length; i += 2) {
        const key = items[i].value.toUpperCase();
        if (key === 'ENVELOPE') {
            out.envelope = envelope(parseEnvelope(items[i + 1]));
        } else if (key === 'BODYSTRUCTURE') {
            out.bodystructure = structure(parseBodystructure(items[i + 1]));
        }
    }
    cases.fetches.push(out);
}
for (const name of names) {
    const encoded = iconv.encode(name, 'utf-7-imap').toString();
    cases.names.push({ name, encoded, decoded: iconv.decode(Buffer.from(encoded), 'utf-7-imap') });
}
writeFileSync(resolve(here, 'message-cases.json'), JSON.stringify(cases, null, 1) + '\n');
console.log(`${cases.fetches.length} fetch responses, ${cases.names.length} names`);
