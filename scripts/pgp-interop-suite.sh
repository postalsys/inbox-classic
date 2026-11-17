#!/usr/bin/env bash
# Runs the OpenPGP interoperability test suite (Sequoia's, the one behind tests.sequoia-pgp.org) against pe-pgp's
# `sop` example, beside Sequoia's sqop, and keeps its report. Not a gate: the suite has tests of things this app
# deliberately refuses (MD5, SHA-1 signatures after the cutoffs, DSA, the unprotected packet), and of SOP options
# the example does not offer. scripts/pgp-interop.sh is the gate.
#
#   scripts/pgp-interop-suite.sh            runs in Docker (Debian trixie) from the Mac or anywhere
#   scripts/pgp-interop-suite.sh --inside   runs here; needs sqop, a C toolchain, nettle and rustup (CI's container)
#
# The report goes to build/pgp-interop-suite/: results.html, results.json and summary.txt (pe-pgp's failures, from
# scripts/pgp-interop-summary.py).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# the suite's commit, moved forward by hand after reading what changed
suite_commit=98af9000ccc212edfb262157e265abe30e6fd828

if [[ "${1:-}" != "--inside" ]]; then
    exec docker run --rm -v "$root:/src" -v pe-pgp-suite-cargo:/root/.cargo -v pe-pgp-suite-rustup:/root/.rustup \
        -v pe-pgp-suite-target:/tmp/target -w /src debian:trixie bash -c '
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null
        apt-get install -y -qq sqop git curl ca-certificates build-essential pkg-config clang nettle-dev libssl-dev \
            libsqlite3-dev python3 >/dev/null 2>&1
        [ -x "$HOME/.cargo/bin/rustup" ] || curl -sSf https://sh.rustup.rs | sh -s -- -y -q --profile minimal >/dev/null
        . "$HOME/.cargo/env"
        rustup default stable >/dev/null 2>&1
        CARGO_TARGET_DIR=/tmp/target scripts/pgp-interop-suite.sh --inside'
fi

out="$root/build/pgp-interop-suite"
mkdir -p "$out"
target="${CARGO_TARGET_DIR:-$root/core/target}"

(cd "$root/core" && cargo build -q --locked --release -p pe-pgp --example sop)
ours="$target/release/examples/sop"

suite="${SUITE_DIR:-$target/openpgp-interoperability-test-suite}"
if [[ "$(git -C "$suite" rev-parse HEAD 2>/dev/null)" != "$suite_commit" ]]; then
    rm -rf "$suite"
    git init -q "$suite"
    git -C "$suite" fetch -q --depth 1 https://gitlab.com/sequoia-pgp/openpgp-interoperability-test-suite.git \
        "$suite_commit"
    git -C "$suite" checkout -q FETCH_HEAD
fi

# the suite names an implementation by its `sop version`; ours says pe-pgp-sop
cat >"$suite/config.json" <<EOF
{
  "drivers": [
    { "path": "$(command -v sqop)" },
    { "path": "$ours" }
  ],
  "rlimits": { "DATA": 4294967296 }
}
EOF

cd "$suite"
# the suite pins a nightly in rust-toolchain.toml, which rustup installs on first use
RUST_MIN_STACK=20971520 CARGO_TARGET_DIR="$target/suite" cargo run -q --release -- \
    --config config.json --json-out "$out/results.json" --html-out "$out/results.html"

python3 "$root/scripts/pgp-interop-summary.py" "$out/results.json" >"$out/summary.txt"
head -1 "$out/summary.txt"
