#!/usr/bin/env bash
# The help's pictures (core/crates/pe-html/help/pictures/<platform>/<shot>.png, `<img src="picture:<shot>">` in a
# topic): the homepage's screenshots of each platform (scripts/homepage-screenshots.sh makes them from the UI tests),
# at most 720 pixels wide and in 256 colors, as they are built into the app. Run after homepage-screenshots.sh when
# a window the help shows changed. Needs ImageMagick.
#
#   scripts/help-pictures.sh
set -euo pipefail
cd "$(dirname "$0")/.."
HOMEPAGE=${HOMEPAGE:-../inboxclassic.com}
# the screenshots the topics show
SHOTS=(read-1-html account-1-form agents-4-send bounce-1-failed all-inboxes-3-accounts)
for platform in windows mac linux; do
    out=core/crates/pe-html/help/pictures/$platform
    mkdir -p "$out"
    for shot in "${SHOTS[@]}"; do
        source="$HOMEPAGE/img/$platform/$shot.png"
        [ -f "$source" ] || { echo "$source is missing: run scripts/homepage-screenshots.sh first" >&2; exit 1; }
        magick "$source" -resize '720x>' -strip -colors 256 "PNG8:$out/$shot.png"
    done
done
du -sh core/crates/pe-html/help/pictures
