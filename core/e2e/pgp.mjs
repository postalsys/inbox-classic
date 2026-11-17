// What the core sent, checked with OpenPGP.js, an implementation that shares nothing with rPGP: used by pgp-check.mjs
// (pe-core's e2e_pgp.rs) and by the harness's POST /pgp/check (the UI tests' write-30 to write-35).
import * as openpgp from 'openpgp';

// the parts of a multipart body: each from after a delimiter line to the line break before the next
export function parts(raw) {
    const head = raw.slice(0, raw.indexOf('\r\n\r\n'));
    const boundary = /boundary="?([^";\r\n]+)"?/i.exec(head.replace(/\r\n[ \t]+/g, ' '))[1];
    const body = raw.slice(raw.indexOf('\r\n\r\n') + 4);
    // the first chunk is the preamble up to the first delimiter, which starts a line of its own
    const first = body.indexOf(`--${boundary}\r\n`);
    const pieces = `\r\n${body.slice(first)}`.split(`\r\n--${boundary}`).slice(1);
    return pieces.filter(p => !p.startsWith('--')).map(p => p.slice(p.indexOf('\r\n') + 2));
}

export function bodyOf(part) {
    return part.slice(part.indexOf('\r\n\r\n') + 4);
}

// the top header block's Content-Type, unfolded and in lower case
function topType(raw) {
    const head = raw.slice(0, raw.indexOf('\r\n\r\n')).replace(/\r\n[ \t]+/g, ' ');
    const match = /^content-type:\s*([^;\r\n]+)/im.exec(head);
    return match ? match[1].trim().toLowerCase() : 'text/plain';
}

async function verified(signature) {
    try {
        await signature.verified;
        return { valid: true };
    } catch (error) {
        return { valid: false, error: String(error) };
    }
}

// A signed message: whether its signature over the first part's exact bytes is good with `signerCert`
export async function verify(raw, signerCert) {
    const [content, signaturePart] = parts(raw);
    const verificationKeys = await openpgp.readKey({ armoredKey: signerCert });
    const message = await openpgp.createMessage({ binary: Buffer.from(content, 'latin1') });
    const signature = await openpgp.readSignature({ armoredSignature: bodyOf(signaturePart) });
    const result = await openpgp.verify({ message, signature, verificationKeys });
    return { ...(await verified(result.signatures[0])), content };
}

// An encrypted message opened with `privateKey` (armored, protected by `passphrase`), its signature checked with
// `signerCert`: the inner entity as text, and whether it was signed and the signature is good
export async function decrypt(raw, privateKey, passphrase, signerCert) {
    const [, encrypted] = parts(raw);
    const decryptionKeys = await openpgp.decryptKey({
        privateKey: await openpgp.readPrivateKey({ armoredKey: privateKey }),
        passphrase
    });
    const verificationKeys = await openpgp.readKey({ armoredKey: signerCert });
    const message = await openpgp.readMessage({ armoredMessage: bodyOf(encrypted) });
    const result = await openpgp.decrypt({ message, decryptionKeys, verificationKeys, format: 'binary' });
    const out = { data: Buffer.from(result.data).toString('utf8'), signed: result.signatures.length > 0 };
    if (out.signed) {
        Object.assign(out, await verified(result.signatures[0]));
    }
    return out;
}

// The key ids an encrypted message names (a hidden recipient's is all zeros)
export async function recipients(raw) {
    const [, encrypted] = parts(raw);
    const message = await openpgp.readMessage({ armoredMessage: bodyOf(encrypted) });
    return message.getEncryptionKeyIDs().map(id => id.toHex().toUpperCase());
}

// The key ids of a key and its subkeys, as recipients() names them
export async function keyIds(armored) {
    const key = await openpgp.readKey({ armoredKey: armored });
    return key.getKeyIDs().map(id => id.toHex().toUpperCase());
}

// The files of an entity: each header block with a name, its type and that name
function files(entity) {
    const found = [];
    for (const block of entity.replace(/\r?\n[ \t]+/g, ' ').split(/\r?\n\r?\n/)) {
        const type = /^content-type:\s*([^;\r\n]+)/im.exec(block);
        const name = /(?:filename|name)\*?="?([^";\r\n]+)"?/i.exec(block);
        if (type && name) {
            found.push({ type: type[1].trim().toLowerCase(), name: name[1].trim() });
        }
    }
    return found;
}

// Everything the UI tests ask of a sent message at once, from a JSON body:
//   { raw, key, passphrase, signer, recipients }
// `raw` is the message's source base64 encoded, as ImapKit's REST API gives it (or `rawText` as text); `key` and
// `passphrase` open an encrypted one (the sender's own key opens it: it is always encrypted to the sender too);
// `signer` is the sender's public key, taken from `key` when left out; `recipients` are public keys to ask about.
// The answer:
//   { kind: "signed" | "encrypted" | "plain", signed, valid, error, text: the inner entity or the signed content,
//     keyIds: what an encrypted one names, to: whether each of `recipients` can open it,
//     attachments: [{ type, name }] of the inner entity }
export async function check(request) {
    const raw = request.rawText ?? Buffer.from(request.raw || '', 'base64').toString('latin1');
    let signer = request.signer;
    if (!signer && request.key) {
        signer = (await openpgp.readPrivateKey({ armoredKey: request.key })).toPublic().armor();
    }
    const out = { kind: 'plain', signed: false };
    const type = topType(raw);
    if (type === 'multipart/signed') {
        const result = await verify(raw, signer);
        Object.assign(out, { kind: 'signed', signed: true, valid: result.valid, error: result.error, text: result.content });
    } else if (type === 'multipart/encrypted') {
        out.kind = 'encrypted';
        out.keyIds = await recipients(raw);
        if (request.key) {
            const result = await decrypt(raw, request.key, request.passphrase || '', signer);
            Object.assign(out, { signed: result.signed, valid: result.valid, error: result.error, text: result.data });
        }
        if (Array.isArray(request.recipients)) {
            out.to = [];
            for (const armored of request.recipients) {
                const ids = await keyIds(armored);
                out.to.push(ids.some(id => out.keyIds.includes(id)));
            }
        }
    } else {
        out.text = raw;
    }
    out.attachments = files(out.text || '');
    return out;
}
