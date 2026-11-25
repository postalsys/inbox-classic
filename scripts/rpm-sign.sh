#!/usr/bin/env bash
# Signs the Fedora packages in dist/ with the release GPG key, here on the Mac, where the key is (rpmsign from
# Homebrew's rpm, `brew install rpm`), then checks each signature in a clean Fedora container against the key as
# rpm.inboxclassic.com publishes it. release.sh runs it after scripts/fedora-package.sh, before hashes.txt, so the
# packages on GitHub and in the repository are the same files.
#
#   scripts/rpm-sign.sh [x86_64|aarch64 ...]     dist/InboxClassic-<arch>.rpm of each (default: both)
set -euo pipefail
cd "$(dirname "$0")/.."
# "Postalsys Releases <releases@postalsys.com>", the key hashes.txt is signed with
GPG_KEY="B6F07B59064F9CCA"
fail() {
    echo "$*" >&2
    exit 1
}
architectures=("$@")
[ ${#architectures[@]} -gt 0 ] || architectures=(x86_64 aarch64)
names=()
for arch in "${architectures[@]}"; do
    [ "$arch" = x86_64 ] || [ "$arch" = aarch64 ] || fail "The architecture is x86_64 or aarch64, not $arch"
    names+=("InboxClassic-$arch.rpm")
done
command -v rpmsign >/dev/null || fail "rpmsign is missing: brew install rpm"
for name in "${names[@]}"; do
    file=dist/$name
    [ -f "$file" ] || fail "$file is missing"
    rpmsign --addsign --define "_gpg_name $GPG_KEY" --define "__gpg $(command -v gpg)" \
        --define "_gpg_digest_algo sha512" "$file" >/dev/null
done
key=$(mktemp)
trap 'rm -f "$key"' EXIT
gpg --export --armor "$GPG_KEY" >"$key"
docker run --rm -v "$PWD/dist:/dist:ro" -v "$key:/key.asc:ro" fedora:44 bash -euo pipefail -c "
    rpm --import /key.asc
    for file in ${names[*]}; do
        checked=\$(rpm -Kv /dist/\$file)
        echo \"\$checked\" | grep -qi 'signature, key fingerprint: [0-9a-f]*${GPG_KEY}: OK' ||
            { echo \"/dist/\$file: not signed with ${GPG_KEY}\" >&2; echo \"\$checked\" >&2; exit 1; }
        echo \"\$file: signed with ${GPG_KEY}\"
    done"
