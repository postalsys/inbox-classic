// Writes mime-cases.json: what libmime's decodeWords and imapflow's getStructuredParams make of the
// inputs below, so the Rust port (tests/conformance.rs) is checked against them. Run with imapflow
// checked out and built next to this repository:
//
//     node generate-mime-cases.mjs [path to imapflow]

import { writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const imapflow = resolve(process.argv[2] || resolve(here, '../../../../../../imapflow'));
const { getStructuredParams } = await import(pathToFileURL(resolve(imapflow, 'dist/esm/tools.js')).href);
// the libmime imapflow uses
const libmime = createRequire(resolve(imapflow, 'package.json'))('libmime');

const words = [
    'plain text',
    '=?UTF-8?Q?J=C3=B5ul_ja_uus_aasta?=',
    '=?utf-8?b?SsO1dWw=?=',
    '=?ISO-8859-1?Q?=F5?= and =?iso-8859-1?q?=e4?=',
    '=?UTF-8?Q?a?= =?UTF-8?Q?b?=',
    '=?UTF-8?Q?a?=   \t =?UTF-8?Q?b?=',
    '=?UTF-8?B?w6E=?= =?UTF-8?B?w6k=?=',
    '=?UTF-8?Q?=C3?= =?UTF-8?Q?=B5?=',
    '=?UTF-8?B?w?= =?UTF-8?B?7U=?=',
    '=?UTF-8?Q?=C3=B5?= =?ISO-8859-1?Q?=E4?=',
    '=?UTF-8?Q?a?= x =?UTF-8?Q?b?=',
    '=?UTF-8?X?abc?=',
    '=?UTF-8?Q?abc',
    '=??Q?a?=',
    'a =? b',
    '=?UTF-8?Q?a=ZZ?=',
    '=?utf-8*en?Q?x?=',
    '=?windows-1257?Q?=E0?=',
    '=?koi8-r?B?0ME=?=',
    '=?iso-2022-jp?B?GyRCJCIbKEI=?=',
    '=?shift_jis?B?gqA=?=',
    'Re: =?UTF-8?Q?Tere_t=C3=A4na?= [x]',
    '"=?UTF-8?Q?Andris_Reinman?=" <andris@example.com>',
    '=?UTF-8?Q?a=20b?=',
    '=?UTF-8?Q?a_b?=',
    '=?us-ascii?Q?plain?=',
    '=?UTF-8?B?8J+Ygg==?= smile',
    'prefix=?UTF-8?Q?x?=suffix'
];

const params = [
    ['CHARSET', 'utf-8', 'name', '=?UTF-8?Q?J=C3=B5ul.txt?='],
    ['filename*1', '.txt', 'filename*0*', "utf-8'et'J%C3%B5ul"],
    ['title*', "iso-8859-1''%F5%E4"],
    ['note*0', 'a ', 'note*1', 'b'],
    ['filename', 'fallback.txt', 'filename*', "utf-8''%C3%B5.txt"],
    ['filename', "utf-8''J%C3%B5ul.txt"],
    ['filename', "it's a file's name"],
    ['x*', "''%C3%B5%Z1"],
    ['name*0', 'part1', 'name*2', 'part3', 'name*1', 'part2'],
    ['FileName*0*', "UTF-8''%E2%82%AC", 'FileName*1*', '%20rates.txt'],
    ['boundary', '----=_Part_0_1.2']
];

const toList = flat => flat.map(value => ({ type: 'STRING', value }));
const cases = {
    words: words.map(input => ({ input, expected: libmime.decodeWords(input) })),
    params: params.map(input => ({ input, expected: getStructuredParams(toList(input)) }))
};
writeFileSync(resolve(here, 'mime-cases.json'), JSON.stringify(cases, null, 1) + '\n');
console.log(`${cases.words.length} word cases, ${cases.params.length} parameter cases`);
