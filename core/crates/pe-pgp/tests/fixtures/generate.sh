#!/usr/bin/env bash
# Makes the fixtures of pe-pgp's tests with other OpenPGP implementations: GnuPG, Sequoia (through sqop, its
# Stateless OpenPGP command line) and OpenPGP.js. Run from anywhere; it runs itself in Docker (Debian trixie) and
# writes into this directory:
#
#   rsa2010.sec.asc        an RSA 2048 key made on 1 January 2010, for the policy's old hash rules
#   interop/<maker>-<kind>/ a key of one implementation and what it made with it:
#       cert.asc           the public certificate
#       secret.asc         the private key, unprotected
#       data.txt           the signed and encrypted bytes (a MIME entity with CRLF line ends)
#       data.sig           a detached signature over data.txt
#       encrypted.asc      data.txt encrypted to the key
#       signed.asc         data.txt signed and encrypted to the key
#
# The output is committed; tests/conformance.rs reads it. Run it again when an implementation's defaults change.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" != "--inside" ]]; then
    exec docker run --rm -v "$here:/out" -v "$here/generate.sh:/generate.sh:ro" debian:trixie bash /generate.sh --inside
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq gnupg sqop nodejs npm >/dev/null 2>&1
mkdir -p /work && cd /work
npm init -y >/dev/null
npm install --silent openpgp@6.2.2 >/dev/null

printf 'Content-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\nHello Bob,\r\nthe contract is attached.\r\n-- \r\nAlice\r\n' >/work/data.txt

export GNUPGHOME=/work/gnupg
mkdir -m 700 -p "$GNUPGHOME"
gpg_batch=(gpg --batch --pinentry-mode loopback --passphrase '')

# the old RSA key, made in 2010
"${gpg_batch[@]}" --faked-system-time '20100101T000000!' --quick-gen-key 'Old <old@example.org>' rsa2048 sign,cert never 2>/dev/null
"${gpg_batch[@]}" --armor --export-secret-keys old@example.org >/out/rsa2010.sec.asc

rm -rf /out/interop
mkdir -p /out/interop

gnupg() {
    local name="$1" algo="$2" uid="$3"
    local dir="/out/interop/gnupg-$name"
    mkdir -p "$dir"
    "${gpg_batch[@]}" --quick-gen-key "$uid" "$algo" default never 2>/dev/null
    local fpr
    fpr="$(gpg --batch --with-colons --list-keys "$uid" | awk -F: '/^fpr/ {print $10; exit}')"
    local sub="$algo"
    [[ "$algo" == ed25519 ]] && sub=cv25519
    "${gpg_batch[@]}" --quick-add-key "$fpr" "$sub" encr never 2>/dev/null
    "${gpg_batch[@]}" --armor --export "$fpr" >"$dir/cert.asc"
    "${gpg_batch[@]}" --armor --export-secret-keys "$fpr" >"$dir/secret.asc"
    cp /work/data.txt "$dir/data.txt"
    "${gpg_batch[@]}" --armor --detach-sign --local-user "$fpr" --output "$dir/data.sig" /work/data.txt
    "${gpg_batch[@]}" --armor --trust-model always --recipient "$fpr" --encrypt --output "$dir/encrypted.asc" /work/data.txt
    "${gpg_batch[@]}" --armor --trust-model always --recipient "$fpr" --local-user "$fpr" --sign --encrypt \
        --output "$dir/signed.asc" /work/data.txt
}

gnupg ed25519 ed25519 'GnuPG Ed25519 <gnupg-ed25519@example.org>'
gnupg rsa3072 rsa3072 'GnuPG RSA <gnupg-rsa@example.org>'
gnupg nistp256 nistp256 'GnuPG P-256 <gnupg-p256@example.org>'

sequoia() {
    local name="$1" uid="$2"
    shift 2
    local dir="/out/interop/sequoia-$name"
    mkdir -p "$dir"
    sqop generate-key "$@" "$uid" >"$dir/secret.asc"
    sqop extract-cert <"$dir/secret.asc" >"$dir/cert.asc"
    cp /work/data.txt "$dir/data.txt"
    sqop sign --as=binary "$dir/secret.asc" </work/data.txt >"$dir/data.sig"
    sqop encrypt "$dir/cert.asc" </work/data.txt >"$dir/encrypted.asc"
    sqop encrypt --sign-with="$dir/secret.asc" "$dir/cert.asc" </work/data.txt >"$dir/signed.asc"
}

sequoia cv25519 'Sequoia <sequoia@example.org>'
if sqop list-profiles generate-key 2>/dev/null | grep -q rfc9580; then
    sequoia v6 'Sequoia v6 <sequoia-v6@example.org>' --profile=rfc9580
fi

cat >/work/openpgpjs.mjs <<'EOF'
import * as openpgp from 'openpgp';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';

const data = readFileSync('/work/data.txt');

async function make(name, options) {
    const dir = `/out/interop/openpgpjs-${name}`;
    mkdirSync(dir, { recursive: true });
    const { privateKey, publicKey } = await openpgp.generateKey({ format: 'armored', ...options });
    writeFileSync(`${dir}/cert.asc`, publicKey);
    writeFileSync(`${dir}/secret.asc`, privateKey);
    writeFileSync(`${dir}/data.txt`, data);
    const key = await openpgp.readPrivateKey({ armoredKey: privateKey });
    const cert = await openpgp.readKey({ armoredKey: publicKey });
    const message = await openpgp.createMessage({ binary: data });
    writeFileSync(`${dir}/data.sig`, await openpgp.sign({ message, signingKeys: key, detached: true }));
    writeFileSync(`${dir}/encrypted.asc`, await openpgp.encrypt({ message, encryptionKeys: cert }));
    writeFileSync(`${dir}/signed.asc`, await openpgp.encrypt({ message, encryptionKeys: cert, signingKeys: key }));
}

await make('curve25519', { userIDs: [{ name: 'OpenPGP.js', email: 'openpgpjs@example.org' }] });
await make('rsa4096', { type: 'rsa', rsaBits: 4096, userIDs: [{ name: 'OpenPGP.js RSA', email: 'openpgpjs-rsa@example.org' }] });
await make('v6', {
    type: 'curve25519',
    userIDs: [{ name: 'OpenPGP.js v6', email: 'openpgpjs-v6@example.org' }],
    config: { v6Keys: true, aeadProtect: true },
});
EOF
node /work/openpgpjs.mjs

chmod -R a+rwX /out/interop /out/rsa2010.sec.asc
ls /out/interop
