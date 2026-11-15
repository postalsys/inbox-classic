// Checks what the core sends with OpenPGP.js, an implementation that shares nothing with rPGP: run by
// pe-core/tests/e2e_pgp.rs with a message file and keys, it prints what it found as JSON.
//
//   node pgp-check.mjs verify <signer-cert.asc> <message.eml>
//   node pgp-check.mjs decrypt <key.asc> <passphrase> <signer-cert.asc> <message.eml>
//   node pgp-check.mjs recipients <message.eml>
import { readFileSync } from 'node:fs';
import * as openpgp from 'openpgp';

const [command, ...args] = process.argv.slice(2);

// the parts of a multipart body: each from after a delimiter line to the line break before the next
function parts(raw) {
    const head = raw.slice(0, raw.indexOf('\r\n\r\n'));
    const boundary = /boundary="?([^";\r\n]+)"?/i.exec(head.replace(/\r\n[ \t]+/g, ' '))[1];
    const body = raw.slice(raw.indexOf('\r\n\r\n') + 4);
    const chunks = body.split(`\r\n--${boundary}`);
    // the first chunk is the preamble up to the first delimiter, which starts a line of its own
    const first = body.indexOf(`--${boundary}\r\n`);
    const pieces = (`\r\n${body.slice(first)}`).split(`\r\n--${boundary}`).slice(1);
    return pieces.filter(p => !p.startsWith('--')).map(p => p.slice(p.indexOf('\r\n') + 2));
}

function bodyOf(part) {
    return part.slice(part.indexOf('\r\n\r\n') + 4);
}

const out = {};
if (command === 'verify') {
    const [certFile, messageFile] = args;
    const raw = readFileSync(messageFile, 'latin1');
    const [content, signaturePart] = parts(raw);
    const verificationKeys = await openpgp.readKey({ armoredKey: readFileSync(certFile, 'utf8') });
    const message = await openpgp.createMessage({ binary: Buffer.from(content, 'latin1') });
    const signature = await openpgp.readSignature({ armoredSignature: bodyOf(signaturePart) });
    const result = await openpgp.verify({ message, signature, verificationKeys });
    try {
        await result.signatures[0].verified;
        out.valid = true;
    } catch (error) {
        out.valid = false;
        out.error = String(error);
    }
    out.content = content;
} else if (command === 'decrypt') {
    const [keyFile, passphrase, certFile, messageFile] = args;
    const raw = readFileSync(messageFile, 'latin1');
    const [, encrypted] = parts(raw);
    const privateKey = await openpgp.decryptKey({
        privateKey: await openpgp.readPrivateKey({ armoredKey: readFileSync(keyFile, 'utf8') }),
        passphrase
    });
    const verificationKeys = await openpgp.readKey({ armoredKey: readFileSync(certFile, 'utf8') });
    const message = await openpgp.readMessage({ armoredMessage: bodyOf(encrypted) });
    const result = await openpgp.decrypt({ message, decryptionKeys: privateKey, verificationKeys, format: 'binary' });
    out.data = Buffer.from(result.data).toString('utf8');
    out.signed = result.signatures.length > 0;
    if (out.signed) {
        try {
            await result.signatures[0].verified;
            out.valid = true;
        } catch (error) {
            out.valid = false;
            out.error = String(error);
        }
    }
} else if (command === 'recipients') {
    const raw = readFileSync(args[0], 'latin1');
    const [, encrypted] = parts(raw);
    const message = await openpgp.readMessage({ armoredMessage: bodyOf(encrypted) });
    out.recipients = message.getEncryptionKeyIDs().map(id => id.toHex().toUpperCase());
}
console.log(JSON.stringify(out));
