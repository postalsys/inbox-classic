// Checks what the core sends with OpenPGP.js (pgp.mjs): run by pe-core/tests/e2e_pgp.rs with a message file and keys,
// it prints what it found as JSON.
//
//   node pgp-check.mjs verify <signer-cert.asc> <message.eml>
//   node pgp-check.mjs decrypt <key.asc> <passphrase> <signer-cert.asc> <message.eml>
//   node pgp-check.mjs recipients <message.eml>
import { readFileSync } from 'node:fs';
import { decrypt, recipients, verify } from './pgp.mjs';

const [command, ...args] = process.argv.slice(2);
const text = file => readFileSync(file, 'utf8');
const raw = file => readFileSync(file, 'latin1');

let out = {};
if (command === 'verify') {
    const [certFile, messageFile] = args;
    out = await verify(raw(messageFile), text(certFile));
} else if (command === 'decrypt') {
    const [keyFile, passphrase, certFile, messageFile] = args;
    out = await decrypt(raw(messageFile), text(keyFile), passphrase, text(certFile));
} else if (command === 'recipients') {
    out.recipients = await recipients(raw(args[0]));
}
console.log(JSON.stringify(out));
