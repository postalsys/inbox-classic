#!/usr/bin/env bash
# Updates the one-time code model built into pe-otp (core/crates/pe-otp/model) from an otp-detect
# checkout: its trees (src/model-data.ts, written by otp-detect's training/train.py) become
# model/model.rs, Rust the crate includes, and model/SOURCE records the otp-detect tag and commit
# and the SHA-256 of the model-data.ts it came from. SHA256SUMS holds the hashes of both files.
#
#   scripts/update-otp-model.sh ../otp-detect    convert the model of an otp-detect checkout
#   scripts/update-otp-model.sh --check          only check the files against SHA256SUMS
#
# The model names the features it was trained on; pe-otp refuses at compile time a model whose
# list differs from its FEATURE_NAMES (src/features.rs), so a model with new features needs the
# features ported first. Run `cargo test -p pe-otp` afterwards, and regenerate the conformance
# fixtures from the same checkout (tests/fixtures/generate.mjs), as the scores change with it.
set -euo pipefail
cd "$(dirname "$0")/.."

MODEL=core/crates/pe-otp/model
FILES=(model.rs SOURCE)

sha256() {
    if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

if [[ "${1:-}" == "--check" ]]; then
    (cd "$MODEL" && sha256 -c SHA256SUMS)
    exit
fi

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <otp-detect checkout> | --check" >&2
    exit 1
fi

SOURCE="$1"
DATA="$SOURCE/src/model-data.ts"
if [[ ! -f "$DATA" ]]; then
    echo "$DATA is missing" >&2
    exit 1
fi

node scripts/otp-model-to-rust.mjs "$DATA" "$MODEL/model.rs"

{
    echo "otp-detect $(git -C "$SOURCE" describe --tags --always --dirty 2>/dev/null || echo unknown)"
    echo "commit $(git -C "$SOURCE" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "src/model-data.ts $(sha256 "$DATA" | cut -d' ' -f1)"
} >"$MODEL/SOURCE"
(cd "$MODEL" && sha256 "${FILES[@]}" >SHA256SUMS)

echo "Updated $MODEL:"
cat "$MODEL/SOURCE" "$MODEL/SHA256SUMS"
