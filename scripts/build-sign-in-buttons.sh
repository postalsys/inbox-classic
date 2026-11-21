#!/usr/bin/env bash
# The Google and Microsoft sign-in buttons of Add Mail Account in each language of pe_i18n::LANGUAGES
# (scripts/languages.sh): app/res/brands/<provider>-sign-in.<lang>.png from the providers' own English pictures
# (google-sign-in.png, microsoft-sign-in.png), their logo and edges kept and the label written in the language, as both
# providers' branding allows. The words are the catalogs' win-sign-in-google and win-sign-in-microsoft, in the fonts the
# pictures use: Roboto Medium for Google (Apache 2.0), its Latin, Latin Extended, Greek and Cyrillic subsets, and
# Selawik Semibold for Microsoft (OFL, Microsoft's open stand-in for Segoe UI), which has no Greek or Cyrillic, so Open
# Sans SemiBold (OFL, by Segoe's designer) writes those. Each letter is written in the first of the fonts that has it,
# and a letter none has stops the script. The fonts are fetched into build/fonts, checked by their hashes; the pictures
# are committed. Run it after those words change or a language is added. Needs ImageMagick (with fontconfig's
# fc-query), perl and curl.
set -euo pipefail
cd "$(dirname "$0")/.."
BRANDS=app/res/brands
FONTS=build/fonts
FONTSOURCE=https://cdn.jsdelivr.net/fontsource/fonts
SELAWIK_URL=https://github.com/microsoft/Selawik/releases/download/1.01/Selawik_Release.zip
SELAWIK_SHA=3f62c51e05e3b5a1e6241cf92a371f0be2ea1183aa87b30718bbd40832a8d423
command -v fc-query >/dev/null || { echo "fc-query (fontconfig) is needed" >&2; exit 1; }

fetch() {
    local url=$1 file=$2 sum=$3
    [ -f "$file" ] || curl -sfL -o "$file" "$url"
    echo "$sum  $file" | shasum -a 256 -c --status || { echo "$file is not the font expected" >&2; exit 1; }
}
mkdir -p "$FONTS/selawik"
fetch "$FONTSOURCE/roboto@5.2.5/latin-500-normal.ttf" "$FONTS/roboto-500.ttf" \
    bbcc980329b3d9b592db88871f8b2d37b3420ef4cb88ef50f5d43104f66b0f34
fetch "$FONTSOURCE/roboto@5.2.5/latin-ext-500-normal.ttf" "$FONTS/roboto-latin-ext-500.ttf" \
    77d64ec7991fc7c0c916a4674dfdeae1ef1ed1105f4d2c08e26467fe20615755
fetch "$FONTSOURCE/roboto@5.2.5/greek-500-normal.ttf" "$FONTS/roboto-greek-500.ttf" \
    4a7e785954eb6396e8f97c89deb7c0ce9d0f117df377ef1daf47d9df0521f083
fetch "$FONTSOURCE/roboto@5.2.5/cyrillic-500-normal.ttf" "$FONTS/roboto-cyrillic-500.ttf" \
    2dbf84acb0d0bc611d3a1262c3cf92edfec015e792f55b8e7b169c31efcd55e9
fetch "$FONTSOURCE/open-sans@5.2.5/greek-600-normal.ttf" "$FONTS/open-sans-greek-600.ttf" \
    e0b3fe7d7ae2252906e6e62ec66242bb973f9c9a8a4d174addbeb63d0683e311
fetch "$FONTSOURCE/open-sans@5.2.5/cyrillic-600-normal.ttf" "$FONTS/open-sans-cyrillic-600.ttf" \
    1283b92fac478fc060552a5dbe812fd411d0e61070c837f08a71c5a2e72e2ee0
fetch "$SELAWIK_URL" "$FONTS/selawik/Selawik_Release.zip" "$SELAWIK_SHA"
[ -f "$FONTS/selawik/selawksb.ttf" ] || unzip -o -q "$FONTS/selawik/Selawik_Release.zip" -d "$FONTS/selawik"

# each provider's fonts, the first one the picture's own
GOOGLE_FONTS=("$FONTS/roboto-500.ttf" "$FONTS/roboto-latin-ext-500.ttf" "$FONTS/roboto-greek-500.ttf"
    "$FONTS/roboto-cyrillic-500.ttf")
MICROSOFT_FONTS=("$FONTS/selawik/selawksb.ttf" "$FONTS/open-sans-greek-600.ttf" "$FONTS/open-sans-cyrillic-600.ttf")

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# a catalog's message, its value alone; English's for a language that has none yet, as the app shows it
words() {
    local found
    found=$(sed -n "s/^$2 = //p" "core/locales/$1/windows.ftl")
    [ -n "$found" ] || found=$(sed -n "s/^$2 = //p" core/locales/en/windows.ftl)
    [ -n "$found" ] || { echo "core/locales/en/windows.ftl has no $2" >&2; exit 1; }
    echo "$found"
}

# the text in runs of one font each: lines of the font's number, a tab and the run. A letter stays in the font of the
# run before it when that font has it, else it takes the first font that has it; one none has stops the script.
runs() {
    local text=$1
    shift
    local charsets=()
    for font in "$@"; do
        charsets+=("$(fc-query -f '%{charset}' "$font")")
    done
    printf '%s\n' "$text" | perl -CSA -e '
        my @sets = map { [map { my ($a, $b) = split /-/; [hex $a, hex($b // $a)] } split " ", $_] } @ARGV;
        sub has { my ($i, $c) = @_; for my $r (@{$sets[$i]}) { return 1 if $c >= $r->[0] && $c <= $r->[1] } 0 }
        my $text = <STDIN>;
        chomp $text;
        my ($font, $run) = (-1, "");
        for my $letter (split //, $text) {
            my $c = ord $letter;
            if ($font >= 0 && has($font, $c)) { $run .= $letter; next }
            my ($found) = grep { has($_, $c) } 0 .. $#sets;
            die sprintf("no font of the button has U+%04X (%s) of \"%s\"\n", $c, $letter, $text) unless defined $found;
            print "$font\t$run\n" if $font >= 0;
            ($font, $run) = ($found, $letter);
        }
        print "$font\t$run\n" if $font >= 0;
    ' "${charsets[@]}"
}

# the words as a picture, trimmed to their ink, in the provider's fonts: each run written alone, put where the run
# before it ends (its advance) and on one baseline with it. Kept in MIFF, ImageMagick's own format, at its full depth.
#   size colour text out fonts...
label() {
    local size=$1 colour=$2 text=$3 out=$4
    shift 4
    local fonts=("$@") list metrics font run ascent advance index=0 top=0 x=0
    local files=() ascents=() lefts=()
    list=$(runs "$text" "${fonts[@]}") || exit 1
    while IFS=$'\t' read -r font run <&3; do
        metrics=$(magick -debug annotate -font "${fonts[$font]}" -pointsize "$size" label:"$run" null: 2>&1 |
            grep -o ' Metrics: .*' | head -1)
        ascent=$(echo "$metrics" | sed -n 's/.*; ascent: \([0-9-]*\).*/\1/p')
        advance=$(echo "$metrics" | sed -n 's/.*; width: \([0-9]*\).*/\1/p')
        magick -background none -fill "$colour" -font "${fonts[$font]}" -pointsize "$size" label:"$run" \
            "miff:$WORK/run-$index.miff"
        files+=("$WORK/run-$index.miff")
        ascents+=("$ascent")
        lefts+=("$x")
        if [ "$ascent" -gt "$top" ]; then top=$ascent; fi
        x=$((x + advance))
        index=$((index + 1))
    done 3<<<"$list"
    local layers=() i
    for ((i = 0; i < ${#files[@]}; i++)); do
        layers+=("${files[$i]}" -geometry "+${lefts[$i]}+$((top - ascents[i]))" -composite)
    done
    magick -size "$((x + 4 * size))x$((4 * size))" xc:none "${layers[@]}" -trim +repage "miff:$out"
}

# one button: the English picture's left part (logo), its middle stretched under the words, its right edge.
#   picture  the English picture        left     where the words start; a little less of the left is kept, no trace
#   top      the top of the words' box           of the English words with it
#   right    the width kept of the right edge
#   size colour                         the words' look   text  the words   out  the picture written   fonts...
button() {
    local picture=$1 left=$2 top=$3 right=$4 size=$5 colour=$6 text=$7 out=$8
    shift 8
    local kept=$((left - 8))
    local width height words_width english_width
    width=$(magick identify -format "%w" "$picture")
    height=$(magick identify -format "%h" "$picture")
    label "$size" "$colour" "$text" "$WORK/words.miff" "$@"
    label "$size" "$colour" "$(english "$picture")" "$WORK/english.miff" "$@"
    words_width=$(magick identify -format "%w" "$WORK/words.miff")
    english_width=$(magick identify -format "%w" "$WORK/english.miff")
    local edge=$((width - right))
    # as much room after the words as the English picture has
    local after=$((edge - left - english_width))
    local total=$((left + words_width + after + right))
    local middle=$((total - kept - right))
    magick \
        \( "$picture" -crop "${kept}x${height}+0+0" +repage \) \
        \( "$picture" -crop "1x${height}+$((edge - 1))+0" +repage -scale "${middle}x${height}!" \) \
        \( "$picture" -crop "${right}x${height}+${edge}+0" +repage \) \
        +append \
        "$WORK/words.miff" -geometry "+${left}+${top}" -composite "$out"
}

english() {
    case "$1" in
        *google*) words en win-sign-in-google ;;
        *) words en win-sign-in-microsoft ;;
    esac
}

for lang in $(scripts/languages.sh --codes); do
    [ "$lang" = en ] && continue
    button "$BRANDS/google-sign-in.png" 103 31 18 29 "#757575" \
        "$(words "$lang" win-sign-in-google)" "$BRANDS/google-sign-in.$lang.png" "${GOOGLE_FONTS[@]}"
    button "$BRANDS/microsoft-sign-in.png" 138 43 20 44 "#5e5e5e" \
        "$(words "$lang" win-sign-in-microsoft)" "$BRANDS/microsoft-sign-in.$lang.png" "${MICROSOFT_FONTS[@]}"
    echo "$BRANDS/google-sign-in.$lang.png $BRANDS/microsoft-sign-in.$lang.png"
done
