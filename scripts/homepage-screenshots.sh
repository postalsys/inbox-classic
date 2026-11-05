#!/usr/bin/env bash
# Puts the screenshots of the three UI end-to-end tests on the homepage (../inboxclassic.com/img/<platform>/): the
# Windows ones of build/ui-e2e (scripts/win-ui-e2e.sh) cropped to the window, without the invisible borders Windows
# draws for resizing; the Mac ones of build/ui-e2e-mac (scripts/mac-ui-e2e.sh) at the size of the page, from the
# Retina pictures; the Linux ones of build/ui-e2e-linux (scripts/linux-ui-e2e.sh) as they are. Run the tests first,
# then this, when a window the homepage shows changed; the page chooses the visitor's platform. Needs ImageMagick.
#
#   scripts/homepage-screenshots.sh [platform...]     windows, mac, linux; all three without
set -euo pipefail
cd "$(dirname "$0")/.."
HOMEPAGE=${HOMEPAGE:-../inboxclassic.com}
# the screenshots the page shows
SHOTS=(read-1-html account-1-form find-2-every-folder write-5-new agents-4-send)
platforms=("$@")
[ ${#platforms[@]} -gt 0 ] || platforms=(windows mac linux)

for platform in "${platforms[@]}"; do
    case "$platform" in
        windows) from=build/ui-e2e ;;
        mac) from=build/ui-e2e-mac ;;
        linux) from=build/ui-e2e-linux ;;
        *) echo "no platform $platform" >&2; exit 1 ;;
    esac
    mkdir -p "$HOMEPAGE/img/$platform"
    for shot in "${SHOTS[@]}"; do
        source="$from/$shot.png"
        [ -f "$source" ] || { echo "$source is missing: run that platform's UI test first" >&2; exit 1; }
        target="$HOMEPAGE/img/$platform/$shot.png"
        case "$platform" in
            windows)
                # 7 pixels of resize border at the left, the right and the bottom; the compose window down to its fields
                # and the start of the text, as the page has room for
                size=$(magick identify -format '%wx%h' "$source")
                width=$((${size%x*} - 14))
                height=$((${size#*x} - 7))
                [ "$shot" = write-5-new ] && height=400
                if [ "$shot" = agents-4-send ]; then
                    # a dialog: no resize border to crop
                    magick "$source" -strip "$target"
                else
                    magick "$source" -crop "${width}x${height}+7+0" +repage -strip "$target"
                fi
                ;;
            mac)
                # the compose window, as on Windows, down to its fields and the start of the text
                crop=""
                [ "$shot" = write-5-new ] && crop="-crop x400+0+0 +repage"
                magick "$source" -resize 50% $crop -strip "$target"
                ;;
            linux)
                crop=""
                [ "$shot" = write-5-new ] && crop="-crop x400+0+0 +repage"
                # the account form is a dialog over the main window: the dialog, where it is in a window of 1090x750
                [ "$shot" = account-1-form ] && crop="-crop 551x459+270+146 +repage"
                # the send confirmation is a dialog over the main window too
                [ "$shot" = agents-4-send ] && crop="-crop 528x481+281+135 +repage"
                magick "$source" $crop -strip "$target"
                ;;
        esac
        echo "$target $(magick identify -format '%wx%h' "$target")"
    done
done
