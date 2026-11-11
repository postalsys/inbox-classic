#!/usr/bin/env bash
# The Google and Microsoft sign-in buttons of Add Mail Account in each language of the catalogs:
# app/res/brands/<provider>-sign-in.<lang>.png from the providers' own English pictures (google-sign-in.png,
# microsoft-sign-in.png), their logo and edges kept and the label written in the language, as both providers' branding
# allows. The words are the catalogs' win-sign-in-google and win-sign-in-microsoft, in the fonts the pictures use:
# Roboto Medium for Google (Apache 2.0) and Selawik Semibold for Microsoft (OFL, Microsoft's open stand-in for Segoe
# UI). The fonts are fetched into build/fonts, checked by their hashes; the pictures are committed. Run it after
# those words change. Needs ImageMagick and curl.
set -euo pipefail
cd "$(dirname "$0")/.."
BRANDS=app/res/brands
FONTS=build/fonts
ROBOTO_URL=https://cdn.jsdelivr.net/fontsource/fonts/roboto@5.2.5/latin-500-normal.ttf
ROBOTO_SHA=bbcc980329b3d9b592db88871f8b2d37b3420ef4cb88ef50f5d43104f66b0f34
SELAWIK_URL=https://github.com/microsoft/Selawik/releases/download/1.01/Selawik_Release.zip
SELAWIK_SHA=3f62c51e05e3b5a1e6241cf92a371f0be2ea1183aa87b30718bbd40832a8d423

fetch() {
    local url=$1 file=$2 sum=$3
    [ -f "$file" ] || curl -sfL -o "$file" "$url"
    echo "$sum  $file" | shasum -a 256 -c --status || { echo "$file is not the font expected" >&2; exit 1; }
}
mkdir -p "$FONTS/selawik"
fetch "$ROBOTO_URL" "$FONTS/roboto-500.ttf" "$ROBOTO_SHA"
fetch "$SELAWIK_URL" "$FONTS/selawik/Selawik_Release.zip" "$SELAWIK_SHA"
[ -f "$FONTS/selawik/selawksb.ttf" ] || unzip -o -q "$FONTS/selawik/Selawik_Release.zip" -d "$FONTS/selawik"

# a catalog's message, its value alone
words() {
    sed -n "s/^$2 = //p" "core/locales/$1/windows.ftl"
}

# one button: the English picture's left part (logo), its middle stretched under the words, its right edge.
#   picture  the English picture        left     where the words start; a little less of the left is kept, no trace
#   top      the top of the words' box           of the English words with it
#   right    the width kept of the right edge
#   font size colour                    the words' look      out  the picture written
button() {
    local picture=$1 left=$2 top=$3 right=$4 font=$5 size=$6 colour=$7 text=$8 out=$9
    local kept=$((left - 8))
    local width height words_width
    width=$(magick identify -format "%w" "$picture")
    height=$(magick identify -format "%h" "$picture")
    words_width=$(magick -background none -font "$font" -pointsize "$size" label:"$text" -trim -format "%w" info:)
    local edge=$((width - right))
    # as much room after the words as the English picture has
    local after
    after=$((edge - left - $(magick -background none -font "$font" -pointsize "$size" label:"$(english "$picture")" -trim -format "%w" info:)))
    local total=$((left + words_width + after + right))
    local middle=$((total - kept - right))
    magick \
        \( "$picture" -crop "${kept}x${height}+0+0" +repage \) \
        \( "$picture" -crop "1x${height}+$((edge - 1))+0" +repage -scale "${middle}x${height}!" \) \
        \( "$picture" -crop "${right}x${height}+${edge}+0" +repage \) \
        +append \
        \( -background none -fill "$colour" -font "$font" -pointsize "$size" label:"$text" -trim +repage \) \
        -geometry "+${left}+${top}" -composite "$out"
}

english() {
    case "$1" in
        *google*) words en win-sign-in-google ;;
        *) words en win-sign-in-microsoft ;;
    esac
}

for lang in de es et fr; do
    button "$BRANDS/google-sign-in.png" 103 31 18 "$FONTS/roboto-500.ttf" 29 "#757575" \
        "$(words "$lang" win-sign-in-google)" "$BRANDS/google-sign-in.$lang.png"
    button "$BRANDS/microsoft-sign-in.png" 138 43 20 "$FONTS/selawik/selawksb.ttf" 44 "#5e5e5e" \
        "$(words "$lang" win-sign-in-microsoft)" "$BRANDS/microsoft-sign-in.$lang.png"
    echo "$BRANDS/google-sign-in.$lang.png $BRANDS/microsoft-sign-in.$lang.png"
done
