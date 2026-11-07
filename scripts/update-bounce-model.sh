#!/usr/bin/env bash
# Updates the bounce classifier's model built into pe-bounce (core/crates/pe-bounce/model) and records
# the SHA-256 of each file in its SHA256SUMS.
#
#   scripts/update-bounce-model.sh ../bounce-classifier    copy the model of a bounce-classifier checkout
#   scripts/update-bounce-model.sh                         download the active model from the Bounce Trainer
#                                                          (BOUNCE_TRAINER_URL, https://bounces.postalsys.com),
#                                                          as bounce-classifier's scripts/update-model.js does
#   scripts/update-bounce-model.sh --check                 only check the files against SHA256SUMS
#
# The labels of the model are an enum in pe-bounce (classify.rs, Label); a model with other labels fails its
# tests. Run `cargo test -p pe-bounce` afterwards, and regenerate the conformance fixtures from a
# bounce-classifier with the same model (tests/fixtures/generate.mjs), as the scores change with it.
set -euo pipefail
cd "$(dirname "$0")/.."

MODEL=core/crates/pe-bounce/model
FILES=(vocab.json labels.json config.json group1-shard1of1.bin)

sha256() {
    if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

if [[ "${1:-}" == "--check" ]]; then
    (cd "$MODEL" && sha256 -c SHA256SUMS)
    exit
fi

if [[ $# -ge 1 ]]; then
    SOURCE="$1/model"
else
    URL="${BOUNCE_TRAINER_URL:-https://bounces.postalsys.com}"
    WORK=$(mktemp -d)
    trap 'rm -rf "$WORK"' EXIT
    echo "Downloading the model from $URL"
    curl -fsSL "$URL/api/model" -o "$WORK/model.tar.gz"
    mkdir "$WORK/model"
    tar -xzf "$WORK/model.tar.gz" -C "$WORK/model"
    SOURCE="$WORK/model"
fi

for file in "${FILES[@]}"; do
    if [[ ! -f "$SOURCE/$file" ]]; then
        echo "$SOURCE/$file is missing" >&2
        exit 1
    fi
done

for file in "${FILES[@]}"; do
    cp "$SOURCE/$file" "$MODEL/$file"
done
(cd "$MODEL" && sha256 "${FILES[@]}" >SHA256SUMS)

echo "Updated $MODEL:"
cat "$MODEL/SHA256SUMS"
grep -E '"(model_hash|trained_at|validation_accuracy)"' "$MODEL/config.json"
