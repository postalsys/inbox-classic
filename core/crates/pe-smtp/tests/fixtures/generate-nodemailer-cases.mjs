// Writes nodemailer-cases.json: what nodemailer makes of a set of inputs with its encoders (quoted-printable,
// base64, encoded words, header folding, RFC 2231 parameters, addresses) and of whole messages built by its
// MailComposer with a fixed date, Message-ID and boundary. tests/conformance.rs checks the Rust port against it.
// Run with the path of a built nodemailer checkout (npm run build there first):
//
//     node <this file> ../nodemailer

import { writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const nodemailer = resolve(process.argv[2] || '../nodemailer');
const load = path => import(pathToFileURL(resolve(nodemailer, 'dist/esm', path)).href);
const mimeFuncs = await load('mime-funcs/index.js');
const qp = await load('qp/index.js');
const base64 = await load('base64/index.js');
const { default: MimeNode } = await load('mime-node/index.js');
const { default: MailComposer } = await load('mail-composer/index.js');

const texts = [
    '',
    'hello',
    'Hello world, just ASCII',
    'Jõgeva õunad on head',
    'Привет, как дела?',
    '日本語のテキスト',
    '😀 party 🎉 time',
    'mixed ascii and ünïcödé words here',
    'quote " and backslash \\ inside',
    'control \x01 char',
    'tab\there',
    'looks like =?utf-8?q?an_encoded?= word',
    'a'.repeat(100),
    'word '.repeat(30).trim(),
    'Ühendatud Kuningriik ja Põhja-Iirimaa '.repeat(4).trim(),
    '你好世界'.repeat(20),
    '  leading and trailing spaces  ',
    'ends with a space ',
    'emoji 🙂'.repeat(10)
];

const bodies = [
    'Hello\r\nworld\r\n',
    'line with trailing space \r\nnext\r\n',
    'Tere õhtust!\r\nKuidas läheb?\r\n',
    'x'.repeat(200) + '\r\n',
    ('Lorem ipsum dolor sit amet, ' + 'ünicode '.repeat(3)).repeat(5) + '\r\n',
    'equals = sign and tab\tend\t\r\n',
    '.leading dot\r\n..two dots\r\n',
    'é'.repeat(40),
    '日本語'.repeat(30) + '\r\n'
];

const cases = { qp: [], base64: [], words: [], fold: [], params: [], names: [], addresses: [], messages: [] };

for (const body of bodies) {
    const encoded = qp.encode(body);
    cases.qp.push({ input: body, encoded, wrapped: qp.wrap(encoded, 76) });
}
for (const text of [...texts, ...bodies]) {
    cases.base64.push({ input: text, wrapped: base64.wrap(base64.encode(Buffer.from(text, 'utf-8')), 76) });
}

const node = new MimeNode();
for (const text of texts) {
    cases.words.push({
        input: text,
        encoding: node._getTextEncoding(text),
        q: mimeFuncs.encodeWord(text, 'Q'),
        b: mimeFuncs.encodeWord(text, 'B'),
        q52: mimeFuncs.encodeWord(text, 'Q', 52),
        b52: mimeFuncs.encodeWord(text, 'B', 52),
        words: mimeFuncs.encodeWords(text, node._getTextEncoding(text), 52, true),
        header: node._encodeHeaderText(text)
    });
    cases.fold.push({ input: 'Subject: ' + node._encodeHeaderText(text), folded: mimeFuncs.foldLines('Subject: ' + node._encodeHeaderText(text), 76) });
    cases.params.push({
        input: text,
        value: mimeFuncs.buildHeaderValue({ value: 'attachment', params: { filename: text } }),
        param: mimeFuncs.buildHeaderParam('filename', text, 50)
    });
    cases.names.push({ input: text, encoded: node._encodeAddressName(text) });
}
for (const text of ['a'.repeat(200), 'word '.repeat(40), 'x'.repeat(70) + ' ' + 'y'.repeat(70), 'short']) {
    cases.fold.push({ input: text, folded: mimeFuncs.foldLines(text, 76) });
}

const addressLists = [
    [{ name: '', address: 'andris@example.com' }],
    [{ name: 'Andris Reinman', address: 'andris@example.com' }],
    [{ name: 'Reinman, Andris', address: 'andris@example.com' }],
    [{ name: 'Jõgeva Linn', address: 'info@jõgeva.ee' }],
    [{ name: '', address: 'üser@jõgeva.ee' }],
    [
        { name: 'Quote "me"', address: 'q@example.com' },
        { name: '', address: 'b@example.com' }
    ],
    [
        {
            name: 'Team',
            group: [
                { name: 'A', address: 'a@example.com' },
                { name: '', address: 'b@example.com' }
            ]
        }
    ],
    [{ name: '', address: 'weird local@example.com' }],
    [{ name: '日本', address: 'jp@example.jp' }]
];
for (const list of addressLists) {
    cases.addresses.push({ input: list, encoded: new MimeNode()._convertAddresses(JSON.parse(JSON.stringify(list))) });
}

const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'base64');
const messages = [
    { name: 'plain ascii', mail: { from: 'Andris <andris@example.com>', to: 'b@example.com', subject: 'Hello', text: 'Hello world!\r\n' } },
    {
        name: 'unicode text',
        mail: {
            from: 'Jõgeva <j@example.com>',
            to: ['Ülle <u@example.com>', 'c@example.com'],
            cc: 'cc@example.com',
            subject: 'Tere õhtust 😀',
            text: 'Tere õhtust!\r\nKuidas läheb? ' + 'pikk rida '.repeat(12) + '\r\n'
        }
    },
    { name: 'html only', mail: { from: 'a@example.com', to: 'b@example.com', subject: 'HTML', html: '<p>Hello <b>world</b></p>' } },
    {
        name: 'alternative',
        mail: { from: 'a@example.com', to: 'b@example.com', subject: 'Both', text: 'Plain version\r\n', html: '<p>HTML version with ünicode</p>' }
    },
    {
        name: 'attachments',
        mail: {
            from: 'a@example.com',
            to: 'b@example.com',
            subject: 'Files',
            text: 'See attached\r\n',
            attachments: [
                { filename: 'report.pdf', content: Buffer.from('%PDF-1.4 '.repeat(20)), contentType: 'application/pdf' },
                { filename: 'õunad ja pirnid väga pika failinimega dokument.txt', content: 'plain text file\r\n', contentType: 'text/plain' }
            ]
        }
    },
    {
        name: 'related',
        mail: {
            from: 'a@example.com',
            to: 'b@example.com',
            subject: 'Inline',
            text: 'logo below\r\n',
            html: '<p>Logo: <img src="cid:logo@example"></p>',
            attachments: [
                { filename: 'logo.png', content: png, contentType: 'image/png', cid: 'logo@example' },
                { filename: 'a.bin', content: Buffer.from([0, 1, 2, 255]), contentType: 'application/octet-stream' }
            ]
        }
    },
    {
        name: 'reply',
        mail: {
            from: 'a@example.com',
            to: 'b@example.com',
            subject: 'Re: Question',
            inReplyTo: '<q1@example.com>',
            references: ['<q0@example.com>', '<q1@example.com>'],
            text: '> quoted\r\nanswer\r\n'
        }
    }
];
for (const { name, mail } of messages) {
    const options = Object.assign({}, mail, { date: new Date('2025-10-06T10:00:00Z'), messageId: '<fixed@example.com>', baseBoundary: 'b0b0b0b0b0b0b0b0' });
    const built = await new MailComposer(options).compile().build();
    const json = { name, mail: Object.assign({}, mail) };
    if (mail.attachments) {
        json.mail.attachments = mail.attachments.map(a => Object.assign({}, a, { content: Buffer.from(a.content).toString('base64') }));
    }
    json.raw = built.toString('base64');
    cases.messages.push(json);
}

writeFileSync(resolve(here, 'nodemailer-cases.json'), JSON.stringify(cases, null, 1) + '\n');
console.log(
    Object.entries(cases)
        .map(([k, v]) => `${k}: ${v.length}`)
        .join(', ')
);
