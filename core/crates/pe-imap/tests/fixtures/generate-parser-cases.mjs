// Writes parser-cases.json: what imapflow's ImapStream and parser make of each response below.
// The Rust port is tested against it (tests/conformance.rs), so the two parsers can not drift
// apart unnoticed. Run from this directory, with imapflow checked out next to this repository:
//
//     node --experimental-strip-types generate-parser-cases.mjs [path to imapflow]
//
// imapflow has to be built (npm run build there), the dist/esm modules are what this loads.

import { writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const imapflow = resolve(process.argv[2] || resolve(here, '../../../../../../imapflow'));
const load = path => import(pathToFileURL(resolve(imapflow, path)).href);

const { ImapStream } = await load('dist/esm/handler/imap-stream.js');
const { parser } = await load('dist/esm/handler/imap-handler.js');
const mimetorture = (await load('test/fixtures/serialized-mimetorture.ts')).default;

const deep = n => '('.repeat(n) + ')'.repeat(n);

// Complete responses as the server sends them, literal data included, without the final CRLF
const inputs = [
    'TAG1 CMD',
    ' TAG CMD',
    '* CMD',
    '+ CMD',
    '+',
    '+ ',
    'TAG1',
    'TAG"1 CMD',
    'TAG1 UID FETCH',
    'TAG1 AUTHENTICATE PLAIN',
    'TAG1  CMD',
    'TAG1 ',
    'TAG1 CM=D',
    '* SEARCH ',
    '* SEARCH',
    '* SEARCH 12 3',
    '* SEARCH 1',
    '* search 7 4294967295',
    '* SEARCH 1 2  ',
    '* SEARCH 0 007 9007199254740991',
    '* SEARCH 9007199254740992',
    '* SEARCH 1  2',
    '* SEARCH 1 2 3 (MODSEQ 917162500)',
    '* SEARCH 1 (modseq 5)  ',
    '* SEARCH 1 (MODSEQ x)',
    '* SEARCH 1 (MODSEQ 12345678901234567890)',
    '* SEARCH (MODSEQ 5)',
    'TAG1 CMD FED',
    'TAG1 CMD FED TED',
    'TAG1 CMD %',
    'TAG1 CMD \\*',
    'TAG1 CMD \\*x',
    '12.82 STATUS [Gmail].Trash (UIDNEXT UNSEEN HIGHESTMODSEQ)',
    'TAG1 CMD "ABCDE"',
    'TAG1 CMD "ABCDE" "DEFGH"',
    'TAG1 CMD "AB\\"CD\\\\E"',
    'TAG1 CMD "ABC',
    'TAG1 CMD "ABC\\',
    'TAG1 CMD (1234)',
    'TAG1 CMD (1234 TERE)',
    'TAG1 CMD (1234)(TERE)',
    'TAG1 CMD ( 1234)',
    'TAG1 CMD (1234 )',
    'TAG1 CMD (1234) ',
    'TAG1 CMD (((TERE)) VANA)',
    'TAG1 CMD (( (TERE)) VANA)',
    'TAG1 CMD (((TERE) ) VANA)',
    'TAG1 CMD (1234',
    'TAG1 CMD 1234)',
    'TAG1 CMD ]',
    'TAG1 CMD {4}\r\nABCD',
    'TAG1 CMD {4}\r\nABCD {3}\r\nEFG',
    'TAG1 CMD ({4}\r\nABCD {4}\r\nEFGH)',
    'TAG1 CMD ({0}\r\n)',
    'TAG1 CMD ({0}\r\n {5}\r\nABCDE)',
    'TAG1 CMD ({3}\r\nABC {0}\r\n {5}\r\nABCDE)',
    'TAG1 CMD ~{4}\r\nAB\x00D',
    'TAG1 CMD ~',
    'TAG1 CMD ~ab',
    'TAG1 CMD (~)',
    'TAG1 CMD ~"x"',
    'TAG1 CMD {00}\r\n',
    'TAG1 CMD {x}',
    'TAG1 CMD\tx',
    'TAG1 CMD \tx',
    '* OK',
    'TAG1 OK',
    '* OK [UIDNEXT 5]',
    '* OK [READ-WRITE] ',
    '* 1 FETCH (RFC822.SIZE 12345678901234)',
    '* OK [HIGHESTMODSEQ 90060115194045007] Ok',
    'TAG1 CMD BODY[]',
    'TAG1 CMD BODY[(KERE)]',
    'TAG1 CMD BODY[HEADER.FIELDS (Subject From) ]',
    'TAG1 CMD BODY.PEEK[1.2.MIME]',
    'TAG1 CMD BINARY[1]',
    'TAG1 CMD XBODY[1]',
    '* OK Hello world!',
    '* OK [CAPABILITY IDLE] Hello world!',
    'TAG1 OK [USEATTR] \\All not supported',
    '* NO [NOUPDATE "B02"] Too many contexts',
    'TAG1 OK [METADATA LONGENTRIES 2199] GETMETADATA complete',
    'TAG1 OK [URLMECH INTERNAL XSAMPLE=P34OKhO7VEkCbsiYY8rGEg==] done',
    'TAG1 NO [REFERRAL IMAP://user;AUTH=*@SERVER2/] Remote Server',
    'TAG1 NO [REFERRAL imap://[::1]/INBOX] Moved',
    'TAG1 NO [REFERRAL imap://host/INBOX',
    '* OK [PERMANENTFLAGS (\\Seen\\*)] Limited',
    '* OK [PERMANENTFLAGS (de:hacking $label kt-evalution [css3-page] \\*)] Flags permitted.',
    '* OK [PERMANENTFLAGS ([css3-page] \\*)] Flags permitted.',
    'TAG1 OK [COPYUID 4 1417051618:1417051620 1421730687:1421730689] COPY completed',
    'TAG1 OK [MODIFIED 7,9] Conditional STORE failed',
    'TAG1 CMD BODY[]<0>',
    'TAG1 CMD BODY[]<12.45>',
    'TAG1 CMD BODY[HEADER.FIELDS (Subject From)]<12.45>',
    'TAG1 CMD BODY[]<01>',
    'TAG1 CMD BODY[]<0.01>',
    'TAG1 CMD BODY[]<0.1.>',
    'TAG1 CMD BODY[]<.1>',
    'TAG1 CMD BODY[]<1x>',
    'TAG1 CMD BODY[]<>',
    'TAG1 CMD BODY[]<1',
    'TAG1 CMD <abc>',
    'TAG1 CMD *:4,5:7 TEST',
    'TAG1 CMD 1:* TEST',
    'TAG1 CMD *:4 TEST',
    'TAG1 CMD *:4,5:',
    'TAG1 CMD *:4,5:TEST TEST',
    'TAG1 CMD *:4,5: TEST',
    'TAG1 CMD *4,5 TEST',
    'TAG1 CMD *,5 TEST',
    'TAG1 CMD 5,* TEST',
    'TAG1 CMD 5, TEST',
    'TAG1 CMD 5:',
    'TAG1 CMD 2024:Q1 1,a',
    'TAG1 CMD *',
    'TAG1 CMD (*)',
    'TAG1 CMD *:*',
    'TAG1 CMD 1:**',
    'TAG1 CMD *1',
    'TAG1 CMD (1:5 7,9)',
    'TAG1 OK [COPYUID 1 1:3 4,5]',
    '* 331 FETCH (ENVELOPE ("=?ISO-8859-1?Q?\\"G=FCnter__Hammerl\\"?="))',
    mimetorture.input,
    'F OK [READ-WRITE] [Gmail]/Visi laiškai selected. (Success) [THROTTLED]',
    'E OK [READ-WRITE] [Gmail]/Вся почта selected. (Success) [THROTTLED]',
    '* LIST (HasNoChildren UnMarked) "/" \'a',
    '* LIST (\\Subscribed \\Sent\\HasNoChildren) "." "SENT"',
    '* LIST (\\Sent\\) "." "SENT"',
    '* STATUS Segregator/Społeczności (MESSAGES 0 UIDNEXT 1 UIDVALIDITY 1)',
    '* STATUS Šegregator/Społeczności (MESSAGES 0 UIDNEXT 1 UIDVALIDITY 1)',
    'X NO Server Unavailable. 15',
    'Server Unavailable. 15',
    'Server Foo{',
    'X BAD Request is throttled. Suggested Backoff Time: 92415 milliseconds',
    '* LIST (\\UnMarked) "." INBOX.[Airmail].Snooze',
    '* 32 FETCH (UID 32 RFC822.SIZE 3991 BODY[2.MIME] "(* 61B literal *)" BODY[2]<0.65536> "(* 6B literal *)")',
    '* 1 FETCH (UID 1 BODY[] {11}\r\nHello world FLAGS (\\Seen))',
    '* 1 FETCH (UID 1 BODYSTRUCTURE ' + deep(101) + ' FLAGS (\\Seen))',
    '* 1 FETCH (UID 1 BODYSTRUCTURE ' + deep(150) + ' ENVELOPE ' + deep(120) + ')',
    '* 1 FETCH (' + deep(120) + ')',
    '* LIST ' + deep(101),
    '* LIST ' + deep(100),
    'A1 NO [XFOO see bar[baz] mailbox is busy',
    'A1 NO [XFOO unterminated',
    'A1 OK [ALERT]text here',
    ')A1 OK x',
    '* Unavailable.',
    '*',
    'A1',
    '* X {5}\r\nabcde',
    '\x00\x00* OK padded',
    '\x00\x00\x00',
    '* 3 EXISTS',
    '* 2 EXPUNGE',
    '* FLAGS (\\Answered \\Flagged \\Deleted \\Seen \\Draft $Forwarded)',
    '* CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE AUTH=PLAIN',
    '* ID ("name" "Dovecot")',
    '* NAMESPACE (("" "/")) NIL NIL',
    '* LIST (\\HasNoChildren) "/" INBOX',
    '* LIST () NIL "Archive"',
    '* LSUB () "." #news.comp.mail.misc',
    '* STATUS "Drafts" (MESSAGES 3 UNSEEN 1)',
    '* ESEARCH (TAG "A282") UID MIN 2 COUNT 3 ALL 2,10:11',
    '* ESEARCH (TAG "A1") UID ALL 1:2:3',
    '* QUOTAROOT INBOX ""',
    '* QUOTA "" (STORAGE 10 512)',
    '* VANISHED (EARLIER) 41,43:116,118,120:211,214:540',
    '* 12 FETCH (FLAGS (\\Seen) INTERNALDATE "17-Jul-1996 02:44:25 -0700" RFC822.SIZE 4286 UID 98 MODSEQ (12121231000))',
    '* 1 FETCH (X-GM-LABELS (\\Inbox "Muuseum" [Gmail]Spam) X-GM-THRID 1278455344230334865)',
    'A1 BAD [CLIENTBUG] Parse error: \x01',
    'A1 OK [CAPABILITY IMAP4rev1 UIDPLUS] Logged in',
    'A1 OK [APPENDUID 38505 3955] APPEND completed',
    '* BYE [ALERT] going down',
    '* PREAUTH [CAPABILITY IMAP4rev1] ready',
    '* 1 FETCH (BODY[HEADER.FIELDS ("From" Subject)] {4}\r\nab\r\n)',
    '* 1 FETCH (BINARY[1] ~{3}\r\n\x00\x01\x02)',
    'TAG1 CMD a\\b',
    'TAG1 CMD (a\\b)',
    'TAG1 OK a\\b(c',
    'TAG1 CMD x"y',
    'TAG1 CMD \x7f',
    'TAG1 CMD é',
    'TAG1 CMD (NIL nil Nil)',
    'TAG1 CMD NIL[1]'
];

const frame = async input => {
    const stream = new ImapStream();
    const out = [];
    stream.on('data', item => {
        out.push({ line: item.payload, literals: item.literals });
        item.next();
    });
    const done = new Promise((resolve, reject) => {
        stream.on('end', resolve);
        stream.on('error', reject);
    });
    stream.end(Buffer.from(input + '\r\n', 'utf8'));
    await done;
    return out;
};

// values as UTF-8 strings: the Rust side reads its bytes the same way
const text = value => (Buffer.isBuffer(value) ? value.toString('utf8') : String(value));

const normalize = node => {
    if (node === null) {
        return null;
    }
    if (Array.isArray(node)) {
        return node.map(normalize);
    }
    const out = { type: node.type, value: text(node.value) };
    if (node.section) {
        out.section = node.section.map(normalize);
    }
    if (node.partial) {
        out.partial = node.partial;
    }
    return out;
};

const cases = [];
for (const input of inputs) {
    const frames = await frame(input);
    for (const { line, literals } of frames) {
        let expected;
        try {
            const parsed = await parser(line, { literals });
            expected = {
                tag: parsed.tag,
                command: parsed.command,
                attributes: (parsed.attributes || []).map(normalize),
                numbers: parsed.numbers || null,
                nullBytesRemoved: parsed.nullBytesRemoved || 0,
                truncatedAttributes: parsed.truncatedAttributes || []
            };
        } catch (err) {
            expected = { error: err.code };
        }
        cases.push({ input, line: line.toString('base64'), literals: literals.map(l => l.toString('base64')), expected });
    }
}

writeFileSync(resolve(here, 'parser-cases.json'), JSON.stringify(cases, null, 1) + '\n');
console.log(`${cases.length} cases from ${inputs.length} inputs`);
