#!/usr/bin/env bash
# The languages of the windows, as pe_i18n::LANGUAGES lists them: one line each, the tag (`de`, or with a region or
# script, `pt-BR`, `sr-Latn`, as the Mac and the file names take it), a tab and the name in itself, English first. Read
# from core/include/languages.tsv, which pe-ffi's build writes from the list, so a language is added in that one list.
#
#   scripts/languages.sh            en<TAB>English, ca<TAB>Català, ...
#   scripts/languages.sh --codes    en ca cs ... pt-BR pt ... sr-Latn ... on one line
set -euo pipefail
TABLE="$(dirname "$0")/../core/include/languages.tsv"
list=$(grep -v '^#' "$TABLE" | cut -f1,2)
[ -n "$list" ] || { echo "No languages found in $TABLE" >&2; exit 1; }
if [ "${1:-}" = "--codes" ]; then
    echo "$list" | cut -f1 | tr '\n' ' ' | sed 's/ $//'
    echo
else
    echo "$list"
fi
