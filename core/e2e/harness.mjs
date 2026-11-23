// Starts ImapKit for an end-to-end test of the Rust core (pe-testkit runs it). The first line on stdin is the
// ImapKit configuration as JSON ({} for the defaults below); the first line on stdout is where it listens:
// { "imap": port, "imaps": port, "smtp": port, "rest": port, "cert": "path of the TLS certificate", "oauth": issuer,
// "pgp": port },
// the issuer of the OAuth provider when the configuration has `oauth` (null without). A configuration with `second`
// starts a second server with that configuration and a mailbox of its own (ImapKit's users share one mailbox), for a
// second account, and adds `"second": { "imap": port, "smtp": port, "rest": port }`; both have the same certificate.
// It also answers `POST http://127.0.0.1:<pgp>/pgp/check` (`"pgp": port` in that line): a sent message checked with
// OpenPGP.js (pgp.mjs `check`), for the UI tests to see that what they signed and encrypted reads as such elsewhere.
// `storageFile` names a JSON file of ImapKit's `storage` to start from, in place of `storage` (the deep test's
// mailboxes, too large for a line).
// The server runs until stdin closes, so it goes away with the test process.

import { createInterface } from 'node:readline';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import imapkit from 'imapkit';
import * as openpgp from 'openpgp';
import { check } from './pgp.mjs';

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

async function start({ storageFile, ...options }) {
    if (storageFile) {
        options.storage = JSON.parse(readFileSync(storageFile, 'utf8'));
    }
    const server = imapkit({
        plugins: ALL_PLUGINS,
        storage: DEFAULT_STORAGE,
        ...options,
        tls: { port: 0, host: '127.0.0.1' },
        smtp: { port: 0, host: '127.0.0.1' },
        rest: { port: 0, host: '127.0.0.1' }
    });
    const imap = await server.start(0, '127.0.0.1');
    // answers leave at once, as real servers send them: with Nagle's algorithm on, a tagged line written after the
    // untagged ones waits for the client's delayed ACK, 40 ms a command on Linux
    for (const listener of [server.server, server.tlsServer]) {
        listener?.on('connection', socket => socket.setNoDelay(true));
    }
    return { server, imap };
}

const { server, imap } = await start(main);
const other = second ? await start(second) : null;

// POST /pgp/check with a JSON body: { raw (base64), key, passphrase, signer, recipients }; the answer as JSON.
// The same server plays keys.openpgp.org and every domain's Web Key Directory for the app (`--key-server`, which
// pe-core uses as the key server and as the base of every domain's directory), so no lookup of a UI test leaves the
// computer. A key is put there with POST /pgp/keys { key (armored), address, wkd }:
// - always by its fingerprint and key id, and its subkeys' (upper case hex): GET /vks/v1/by-fingerprint/<FPR> and
//   GET /vks/v1/by-keyid/<ID>, as Find Key asks for the key of a signature;
// - with `address`, by that address: GET /vks/v1/by-email/<address>;
// - with `address` and `wkd: true`, also in the address's domain's Web Key Directory, as pe-keys asks it with a
//   test base: GET /advanced/.well-known/openpgpkey/<domain>/hu/<hash>?l=<local> (and /direct/.well-known/openpgpkey/
//   hu/<hash>, which pe-keys asks only when the advanced host can not be reached), the key binary.
// Everything else is 404. GET /pgp/lookups lists each key lookup asked ({ kind: "email" | "fingerprint" | "keyid" |
// "wkd", value: the address (a directory's: its `l` and domain), fingerprint or key id, found }), for the tests to see
// what was asked.
// Publishing as keys.openpgp.org answers it: POST /vks/v1/upload { keytext } gives a token and each address of the key
// "unpublished", POST /vks/v1/request-verify { token, addresses } makes those "pending" (the confirmation mail the real
// one sends); GET /pgp/uploads lists what was uploaded ({ fingerprint, addresses, asked }) for the tests to check.
const served = new Map();
const byHandle = new Map();
const directory = new Map();
const lookups = [];
const uploads = [];

// The Web Key Directory's name for a local part: z-base-32 of the SHA-1 of it in lower case (pe-keys `wkd_hash`)
function wkdHash(local) {
    const alphabet = 'ybndrfg8ejkmcpqxot1uwisza345h769';
    const digest = createHash('sha1').update(local.toLowerCase()).digest();
    let out = '';
    let buffer = 0;
    let bits = 0;
    for (const byte of digest) {
        buffer = (buffer << 8) | byte;
        bits += 8;
        while (bits >= 5) {
            bits -= 5;
            out += alphabet[(buffer >> bits) & 31];
        }
        buffer &= (1 << bits) - 1;
    }
    return bits > 0 ? out + alphabet[(buffer << (5 - bits)) & 31] : out;
}

// What a GET asks the key server or a directory for: { kind, value, key } (key undefined when there is none)
function lookup(path, query) {
    const local = (query.get('l') || '').toLowerCase();
    const vks = /^\/vks\/v1\/(by-email|by-fingerprint|by-keyid)\/(.+)$/.exec(path);
    if (vks) {
        const value = decodeURIComponent(vks[2]);
        if (vks[1] === 'by-email') {
            return { kind: 'email', value: value.toLowerCase(), key: served.get(value.toLowerCase()) };
        }
        const handle = value.toUpperCase();
        return { kind: vks[1].slice(3), value: handle, key: byHandle.get(handle) };
    }
    const advanced = /^\/advanced\/\.well-known\/openpgpkey\/([^/]+)\/hu\/([^/]+)$/.exec(path);
    if (advanced) {
        const [hash, domain] = [advanced[2], advanced[1].toLowerCase()];
        return { kind: 'wkd', value: `${local}@${domain}`, key: directory.get(`${hash}@${domain}`) };
    }
    const direct = /^\/direct\/\.well-known\/openpgpkey\/hu\/([^/]+)$/.exec(path);
    if (direct) {
        const found = [...directory].find(([name]) => name.startsWith(`${direct[1]}@`));
        return { kind: 'wkd', value: `${local}@`, key: found && found[1] };
    }
    return null;
}

const pgp = createServer((req, res) => {
    const answer = (status, body) => {
        res.writeHead(status, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(body));
    };
    const url = new URL(req.url, 'http://127.0.0.1');
    const path = url.pathname;
    if (req.method === 'GET' && path === '/pgp/uploads') {
        return answer(200, uploads);
    }
    if (req.method === 'GET' && path === '/pgp/lookups') {
        return answer(200, lookups);
    }
    if (req.method === 'GET') {
        const asked = lookup(path, url.searchParams);
        if (asked) {
            lookups.push({ kind: asked.kind, value: asked.value, found: Boolean(asked.key) });
        }
        if (asked && asked.key) {
            res.writeHead(200, { 'Content-Type': asked.kind === 'wkd' ? 'application/octet-stream' : 'application/pgp-keys' });
            return res.end(asked.key);
        }
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        return res.end('not found');
    }
    const publishing = path === '/vks/v1/upload' || path === '/vks/v1/request-verify';
    if (req.method !== 'POST' || (path !== '/pgp/check' && path !== '/pgp/keys' && !publishing)) {
        return answer(404, { error: 'POST /pgp/check, /pgp/keys or a keys.openpgp.org publish' });
    }
    const chunks = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', async () => {
        try {
            const body = JSON.parse(Buffer.concat(chunks).toString('utf8'));
            if (path === '/pgp/keys') {
                const armored = String(body.key);
                const key = await openpgp.readKey({ armoredKey: armored });
                const handles = [key, ...key.subkeys].flatMap(k => [k.getFingerprint(), k.getKeyID().toHex()]);
                for (const handle of handles) {
                    byHandle.set(handle.toUpperCase(), armored);
                }
                if (body.address) {
                    const address = String(body.address).toLowerCase();
                    served.set(address, armored);
                    if (body.wkd) {
                        const at = address.lastIndexOf('@');
                        directory.set(`${wkdHash(address.slice(0, at))}@${address.slice(at + 1)}`, Buffer.from(key.write()));
                    }
                }
                return answer(200, { ok: true, fingerprint: key.getFingerprint().toUpperCase() });
            }
            if (path === '/vks/v1/upload') {
                const key = await openpgp.readKey({ armoredKey: String(body.keytext) });
                const addresses = key.users
                    .map(user => user.userID && user.userID.email)
                    .filter(Boolean)
                    .map(address => address.toLowerCase());
                const token = `t${uploads.length}`;
                uploads.push({ token, fingerprint: key.getFingerprint().toUpperCase(), addresses, asked: [] });
                const status = Object.fromEntries(addresses.map(address => [address, 'unpublished']));
                return answer(200, { key_fpr: key.getFingerprint().toUpperCase(), token, status });
            }
            if (path === '/vks/v1/request-verify') {
                const upload = uploads.find(u => u.token === body.token);
                if (!upload) return answer(400, { error: 'unknown token' });
                upload.asked = (body.addresses || []).map(a => String(a).toLowerCase());
                const status = Object.fromEntries(upload.addresses.map(a => [a, upload.asked.includes(a) ? 'pending' : 'unpublished']));
                return answer(200, { key_fpr: upload.fingerprint, token: upload.token, status });
            }
            answer(200, await check(body));
        } catch (error) {
            answer(400, { error: String(error) });
        }
    });
});
await new Promise(resolve => pgp.listen(0, '127.0.0.1', resolve));

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
        pgp: pgp.address().port,
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
