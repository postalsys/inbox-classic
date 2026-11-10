// Writes message-cases.json: what postal-mime makes of the messages its own tests parse
// (recorded-inputs.json, made by record-postal-mime-inputs.mjs) and of its fixture .eml files,
// what its address parser makes of the inputs of its address parser tests, and its HTML and text
// conversions. tests/message_conformance.rs checks the Rust port against it. Run from the
// postal-mime directory, so its tsx is found, with the UTC time zone and the en-US locale (the
// dates of attached messages are formatted with Intl):
//
//     cd ../postal-mime && TZ=UTC LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 node --import tsx <this file> [path to postal-mime]

import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const postalMime = resolve(process.argv[2] || process.cwd());
const load = path => import(pathToFileURL(resolve(postalMime, path)).href);
const { default: PostalMime } = await load('src/postal-mime.ts');
const { default: addressParser } = await load('src/address-parser.ts');
const { htmlToText, textToHtml } = await load('src/text-format.ts');

const recorded = JSON.parse(readFileSync(resolve(here, 'recorded-inputs.json'), 'utf8')).map(b64 => Buffer.from(b64, 'base64'));
const fixtures = readdirSync(resolve(postalMime, 'test/fixtures'))
    .filter(name => name.endsWith('.eml'))
    .map(name => readFileSync(resolve(postalMime, 'test/fixtures', name)));

const messages = [];
for (const raw of [...fixtures, ...recorded]) {
    let expected;
    try {
        const email = await PostalMime.parse(new Uint8Array(raw), { attachmentEncoding: 'base64' });
        delete email.otp;
        delete email.headerLines;
        expected = email;
    } catch (err) {
        expected = { error: err.code || String(err) };
    }
    messages.push({ raw: raw.toString('base64'), expected });
}

// the string arguments of addressParser('...') calls in its tests
const source = readFileSync(resolve(postalMime, 'test/address-parser-test.ts'), 'utf8');
const addressInputs = [...source.matchAll(/addressParser\('((?:[^'\\]|\\.)*)'\)/g)].map(m => m[1].replace(/\\(.)/g, '$1'));
addressInputs.push(
    'Andris <andris@example.com>',
    '"Reinman, Andris" <a@b.c>, d@e.f',
    'a@b.c (Andris)',
    '=?UTF-8?Q?J=C3=B5ul?= <j@x.ee>',
    'Team: a@b.c, Bob <d@e.f>;',
    'undisclosed-recipients:;',
    'write to me@example.com today',
    '"quoted local"@example.com',
    'user(comment)@example.com',
    '<@route:user@example.com>',
    'Last, First <first@example.com>',
    '',
    // whitespace and comments around a dot of the domain (postal-mime 6467257, GHSA-jh3p-792r-98gm)
    'ceo@victim.example .allowed.example',
    'ceo@victim.example. allowed.example',
    'a@b . c',
    'ceo@victim.example(x).allowed.example',
    'ceo@victim.example (x) .allowed.example',
    'ceo@victim.example.(x)allowed.example',
    'ceo@victim.example (x) . (y) allowed.example',
    'CEO <ceo@victim.example .allowed.example>',
    'CEO <ceo@victim.example(x).allowed.example>',
    'Name <ceo@victim.example(x) . (y) allowed.example>',
    '"a b"@victim.example (x) .allowed.example',
    'G: ceo@victim.example .allowed.example;',
    'ceo@victim.example .allowed.example, x@y.z',
    'user@company(x).com@attacker.net',
    '"user"@company(x).com@attacker.net',
    'user@company(x).com(y)@attacker.net',
    'user@company.com(y)@attacker.net',
    'ceo@victim\u00a0.example',
    'ceo@victim\ufeff.example',
    'CEO <ceo@victim.\u3000example>',
    'ceo@victim(x) .example',
    'ceo@victim.(x) example',
    'ceo@victim (x).example',
    'ceo@victim.\t(x)\texample',
    'ceo@victim\r\n .example',
    'john@example.com John',
    'john@example.com .',
    'a@b.c d@e.f',
    'user@good.com(x)evil.com',
    '<a@b . >',
    '<a@b . : c>',
    // a control character in an addr-spec names no mailbox, in a name it is left out
    'ceo@vic\x01tim.example',
    'c\x1feo@victim.example',
    'ceo@victim.example\x0b.evil.example',
    'CEO <ceo@vic\x00tim.example>',
    'G: a@b\x01c;',
    'ceo@victim.example \x01.evil.example',
    'x <ceo@victim.example \x01>',
    '"a\x01b"@x.example',
    'C\x01EO ceo@victim.example',
    'x <a@b.example>, ceo@vic\x01tim.example, y <c@d.example>',
    'C\x01EO <ceo@victim.example>',
    '"C\x01EO" <ceo@victim.example>',
    'ceo@victim.example (C\x02EO)',
    '=?utf-8?Q?C\x01EO?=',
    'G\x01: a@b.example;',
    '=?utf-8?q?a?= \x01',
    'a@b.example, \x01, c@d.example',
    'G: \x01;',
    'ceo@victim.example\r\n .evil.example'
);
const addresses = addressInputs.map(input => ({ input, expected: addressParser(input) }));

const html = [
    '<html><head><style>p{}</style></head><body><p>Hello <b>world</b></p><ul><li>one</li></ul><a href="https://x.ee">link</a><script>x()</script><!-- c --></body></html>',
    '<div>a<br>b<br/>c</div><table><tr><td>1</td><td>2</td></tr></table>',
    'x &amp; y &lt;z&gt; &#228; &#xE4; &auml &bogus; &#0; &#150;',
    '<p>first</p>\r\n\r\n\r\n<p>second</p><hr>end',
    '<!DOCTYPE html><html><body>only body</body></html> trailing',
    'plain text without tags',
    '<a href=unquoted>u</a> <a name="x">no href</a> <A HREF="https://UP.ee">UP</A>',
    '<li>\n  item</li><LI>two'
];
const texts = [' a < b\nc ', 'x & y "q" \'s\' ?', 'line1\nline2\n\nline4', ''];
const conversions = {
    htmlToText: html.map(input => ({ input, expected: htmlToText(input) })),
    textToHtml: texts.map(input => ({ input, expected: textToHtml(input) }))
};

writeFileSync(resolve(here, 'message-cases.json'), JSON.stringify({ messages, addresses, conversions }) + '\n');
console.log(`${messages.length} messages, ${addresses.length} addresses, ${html.length + texts.length} conversions`);
