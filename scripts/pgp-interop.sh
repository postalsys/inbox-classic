#!/usr/bin/env bash
# Checks pe-pgp against other OpenPGP implementations, in both directions: Sequoia (sqop, a code base that shares
# nothing with rPGP) and GnuPG. What one makes, the other opens and verifies.
#
#   scripts/pgp-interop.sh            runs in Docker (Debian trixie) from the Mac or anywhere
#   scripts/pgp-interop.sh --inside   runs here; needs sqop, gpg and cargo (CI's container)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" != "--inside" ]]; then
    # the cargo registry and the build are kept in volumes, so a second run does not start from nothing
    exec docker run --rm -v "$root:/src" -v pe-pgp-interop-cargo:/root/.cargo -v pe-pgp-interop-target:/tmp/target \
        -w /src debian:trixie bash -c '
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null && apt-get install -y -qq sqop gnupg curl ca-certificates gcc >/dev/null 2>&1
        [ -x "$HOME/.cargo/bin/cargo" ] || curl -sSf https://sh.rustup.rs | sh -s -- -y -q --profile minimal >/dev/null
        . "$HOME/.cargo/env"
        # an install cut short leaves rustup in the volume without a toolchain
        rustup default stable >/dev/null 2>&1
        CARGO_TARGET_DIR=/tmp/target scripts/pgp-interop.sh --inside'
fi

cd "$root/core"
cargo build -q --locked -p pe-pgp --example sop
ours="${CARGO_TARGET_DIR:-$root/core/target}/debug/examples/sop"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"

failed=0
check() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>"$work/err"; then
        echo "ok    $name"
    else
        echo "FAIL  $name"
        sed 's/^/      /' "$work/err"
        failed=1
    fi
}

printf 'Content-Type: text/plain; charset=utf-8\r\n\r\nHello, the meeting moved to Thursday.\r\n' >data.txt

# a key of ours, one of Sequoia's (v4 and, when sqop has the profile, v6)
"$ours" generate-key 'Ours <ours@example.org>' >ours.key
"$ours" extract-cert <ours.key >ours.cert
sqop generate-key 'Sequoia <sequoia@example.org>' >sq.key
sqop extract-cert <sq.key >sq.cert
others=(sq)
if sqop list-profiles generate-key 2>/dev/null | grep -q rfc9580; then
    sqop generate-key --profile=rfc9580 'Sequoia v6 <sequoia6@example.org>' >sq6.key
    sqop extract-cert <sq6.key >sq6.cert
    others+=(sq6)
fi

"$ours" sign ours.key <data.txt >ours.sig
printf 'changed' >changed.txt

for other in "${others[@]}"; do
    # ours signs, Sequoia verifies; Sequoia signs, ours verifies
    check "$other verifies our signature" sqop verify ours.sig ours.cert <data.txt
    sqop sign "$other.key" <data.txt >"$other.sig"
    check "we verify $other's signature" "$ours" verify "$other.sig" "$other.cert" <data.txt
    # a changed text must not verify, either way
    check "$other refuses our signature over changed text" bash -c "! sqop verify ours.sig ours.cert <changed.txt"
    check "we refuse $other's signature over changed text" bash -c "! '$ours' verify $other.sig $other.cert <changed.txt"

    # ours encrypts and signs to Sequoia's key; Sequoia decrypts and verifies
    "$ours" encrypt --sign-with=ours.key "$other.cert" <data.txt >to-other.asc
    rm -f v.txt out.txt
    check "$other decrypts and verifies ours" bash -c "
        sqop decrypt --verify-with=ours.cert --verifications-out=v.txt $other.key <to-other.asc >out.txt &&
        cmp out.txt data.txt && grep -q . v.txt"
    # Sequoia encrypts and signs to ours; ours decrypts and verifies
    sqop encrypt --sign-with="$other.key" ours.cert <data.txt >to-ours.asc
    rm -f v.txt out.txt
    check "we decrypt and verify $other's" bash -c "
        '$ours' decrypt --verify-with=$other.cert --verifications-out=v.txt ours.key <to-ours.asc >out.txt &&
        cmp out.txt data.txt && grep -q . v.txt"
done

# GnuPG: it reads SEIPDv1 only, which is what a message to its key gets
export GNUPGHOME="$work/gnupg"
mkdir -m 700 "$GNUPGHOME"
gpg=(gpg --batch --quiet --pinentry-mode loopback --passphrase '' --trust-model always)
"${gpg[@]}" --quick-gen-key 'GnuPG <gnupg@example.org>' ed25519 default never 2>/dev/null
fpr="$(gpg --batch --with-colons --list-keys gnupg@example.org | awk -F: '/^fpr/ {print $10; exit}')"
"${gpg[@]}" --quick-add-key "$fpr" cv25519 encr never 2>/dev/null
"${gpg[@]}" --armor --export "$fpr" >gpg.cert
"${gpg[@]}" --armor --export-secret-keys "$fpr" >gpg.key
"${gpg[@]}" --import ours.cert 2>/dev/null

"$ours" encrypt --sign-with=ours.key gpg.cert <data.txt >to-gpg.asc
gpg_decrypts() {
    "${gpg[@]}" --status-fd 1 --output out.txt --decrypt to-gpg.asc 2>/dev/null | grep -q GOODSIG && cmp out.txt data.txt
}
rm -f out.txt
check "GnuPG decrypts and verifies ours" gpg_decrypts
check "GnuPG verifies our signature" "${gpg[@]}" --verify ours.sig data.txt
rm -f to-ours.asc v.txt out.txt
"${gpg[@]}" --armor --recipient ours@example.org --local-user "$fpr" --sign --encrypt --output to-ours.asc data.txt
check "we decrypt and verify GnuPG's" bash -c "
    '$ours' decrypt --verify-with=gpg.cert --verifications-out=v.txt ours.key <to-ours.asc >out.txt &&
    cmp out.txt data.txt && grep -q . v.txt"
"${gpg[@]}" --armor --detach-sign --local-user "$fpr" --output gpg.sig data.txt
check "we verify GnuPG's signature" "$ours" verify gpg.sig gpg.cert <data.txt

exit "$failed"
