// Writes dom-cases.json: the trees node-html-parser builds (parse(html, { comment: false }), as
// email-content calls it) for hand written edge cases and for every HTML body in cases.json.
// src/dom.rs is checked against it. Edge cases keep the whole dump; the real bodies keep a 64 bit
// FNV-1a hash of it, so the file stays small. Run after generate-cases.mjs:
//
//     node generate-dom-cases.mjs [path to email-content]

import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(process.argv[2] || resolve(here, '../../../../../../email-content'));
const require = createRequire(resolve(root, 'package.json'));
const { parse, NodeType } = require('node-html-parser');
const { isPathologicalHtml } = require(resolve(root, 'dist/segment/html-blocks.js'));

function dump(html) {
    let out = '';
    const visit = node => {
        if (node.nodeType === NodeType.TEXT_NODE) {
            out += `t${node.range[0]},${node.range[1]};`;
        } else if (node.nodeType === NodeType.ELEMENT_NODE) {
            out += `<${node.rawTagName} ${node.range[0]},${node.range[1]}(`;
            node.childNodes.forEach(visit);
            out += ')';
        }
    };
    parse(html, { comment: false }).childNodes.forEach(visit);
    return out;
}

function fnv64(text) {
    let hash = 0xcbf29ce484222325n;
    for (const byte of Buffer.from(text, 'utf8')) {
        hash ^= BigInt(byte);
        hash = (hash * 0x100000001b3n) & 0xffffffffffffffffn;
    }
    return hash.toString(16);
}

const edge = [
    '',
    'plain',
    '<p>a<p>b',
    '<div><b>x</div>y',
    '<b>x</i>',
    '<a><b><c>y</a></b>',
    '<td><font>x</td>',
    '<table><tr><td>a<td>b</table>',
    '<ul><li>a<li>b</ul>',
    '<p>x</div>',
    '<div><p>x</div>',
    '<span><p>x</span>',
    '<a title="x>y">t</a>',
    '<a b="x>y" c>t</a>',
    '<a b=\'x"y\' c="z\'">t</a>',
    '<a b="x"y>t</a>',
    '<a b="unterminated>t</a><p>after</p>',
    '<a "<a "<a ">x',
    '<br/><br /><Br>text',
    '<img src=x>a<hr>b',
    '<pre><b>bold</b></pre>tail',
    '<pre>unterminated <b>',
    '<PRE>x</PRE>y',
    '<script>if (a < b) {}</script>z',
    '<style>p{}</style><noscript>n</noscript>',
    '<!-- c -->a<!--b',
    '<![CDATA[x<y]]>z',
    '<!DOCTYPE html><html><head><title>t</title></head><body>b</body></html>',
    '<![if !supportLists]>item<![endif]>',
    '<?xml version="1.0"?><o:p>x</o:p>',
    'a < b and c > d',
    '<a "x">y',
    '<p class=x>y</p>',
    '<dl><dt>a<dd>b</dl>',
    '<h1>a<h1>b',
    '<b><b>x',
    '<div><div>x',
    '<li>a</ul>b',
    '<p>a<a>b</p>c',
    '<div>é€\u{1F600}<b>x</b></div>',
    '<documentfragmentcontainer>x</documentfragmentcontainer>y',
    '<a href="x',
    'x<b',
    '<div class="a" CLASS="b" id=c>t</div>'
];

const cases = edge.map(html => ({ html, dump: dump(html) }));

const bodies = new Set();
for (const entry of JSON.parse(readFileSync(resolve(here, 'cases.json'), 'utf8'))) {
    for (const section of entry.content.sections ?? [entry.content]) {
        if (typeof section.html === 'string' && section.html.trim()) {
            bodies.add(section.html);
        }
    }
}
// Indexes count every distinct body in order; pathological ones are never parsed and get no hash.
const hashed = [...bodies]
    .map((html, index) => ({ index, html }))
    .filter(({ html }) => !isPathologicalHtml(html))
    .map(({ index, html }) => ({ index, hash: fnv64(dump(html)) }));

writeFileSync(resolve(here, 'dom-cases.json'), JSON.stringify({ edge: cases, hashes: hashed }));
console.error(`wrote ${cases.length} edge cases and ${hashed.length} body hashes`);
