// Starts ImapKit for an end-to-end test of the Rust core (pe-testkit runs it). The first line on stdin is the
// ImapKit configuration as JSON ({} for the defaults below); the first line on stdout is where it listens:
// { "imap": port, "imaps": port, "smtp": port, "rest": port, "cert": "path of the TLS certificate", "oauth": issuer },
// the issuer of the OAuth provider when the configuration has `oauth` (null without). A configuration with `second`
// starts a second server with that configuration and a mailbox of its own (ImapKit's users share one mailbox), for a
// second account, and adds `"second": { "imap": port, "smtp": port, "rest": port }`; both have the same certificate.
// The server runs until stdin closes, so it goes away with the test process.

import { createInterface } from 'node:readline';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import imapkit from 'imapkit';

// Every plugin that loads together with the others, as imapflow's tests use them
const ALL_PLUGINS = [
    'APPENDLIMIT',
    'AUTH-PLAIN',
    'BINARY',
    'CATENATE',
    'COMPRESS',
    'CONDSTORE',
    'CONTEXT=SEARCH',
    'CONTEXT=SORT',
    'CREATE-SPECIAL-USE',
    'ENABLE',
    'ESEARCH',
    'ESORT',
    'ID',
    'IDLE',
    'IMAP4rev2',
    'LIST-EXTENDED',
    'LIST-STATUS',
    'LITERALPLUS',
    'MESSAGELIMIT',
    'METADATA',
    'MOVE',
    'MULTIAPPEND',
    'MULTISEARCH',
    'NAMESPACE',
    'NOTIFY',
    'OAUTHBEARER',
    'OBJECTID',
    'PARTIAL',
    'PREVIEW',
    'QRESYNC',
    'QUOTA',
    'REPLACE',
    'SASL-IR',
    'SAVEDATE',
    'SEARCHRES',
    'SORT',
    'SORT=DISPLAY',
    'SPECIAL-USE',
    'STARTTLS',
    'STATUS=SIZE',
    'THREAD=ORDEREDSUBJECT',
    'THREAD=REFERENCES',
    'UIDPLUS',
    'UNAUTHENTICATE',
    'UNSELECT',
    'UTF8=ACCEPT',
    'X-GM-EXT-1',
    'XOAUTH2'
];

// A mailbox tree with the usual special-use folders
const DEFAULT_STORAGE = {
    INBOX: {},
    '': {
        separator: '/',
        folders: {
            Archive: { 'special-use': '\\Archive' },
            Drafts: { 'special-use': '\\Drafts' },
            Junk: { 'special-use': '\\Junk' },
            Sent: { 'special-use': '\\Sent' },
            Trash: { 'special-use': '\\Trash' }
        }
    }
};

const lines = createInterface({ input: process.stdin });
const first = await new Promise(resolve => lines.once('line', resolve));
// Windows PowerShell may start what it writes with a byte order mark
const config = JSON.parse((first || '').replace(/^\uFEFF/, '') || '{}');

const { second, ...main } = config;

async function start(options) {
    const server = imapkit({
        plugins: ALL_PLUGINS,
        storage: DEFAULT_STORAGE,
        ...options,
        tls: { port: 0, host: '127.0.0.1' },
        smtp: { port: 0, host: '127.0.0.1' },
        rest: { port: 0, host: '127.0.0.1' }
    });
    const imap = await server.start(0, '127.0.0.1');
    return { server, imap };
}

const { server, imap } = await start(main);
const other = second ? await start(second) : null;

const require = createRequire(import.meta.url);
const cert = join(dirname(require.resolve('imapkit/package.json')), 'cert', 'server.crt');
process.stdout.write(
    JSON.stringify({
        imap,
        imaps: server.tlsServer.address().port,
        smtp: server.smtpServer.server.address().port,
        rest: server.restServer.address().port,
        cert,
        oauth: server.oauth ? server.oauth.issuer : null,
        second: other
            ? {
                  imap: other.imap,
                  smtp: other.server.smtpServer.server.address().port,
                  rest: other.server.restServer.address().port
              }
            : undefined
    }) + '\n'
);

lines.on('close', () => process.exit(0));
