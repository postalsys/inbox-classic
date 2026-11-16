#!/usr/bin/env bash
# The languages of the windows, as pe_i18n::LANGUAGES (core/crates/pe-i18n/src/lib.rs) lists them: one line each, the
# tag (`de`, or with a region or script, `pt-BR`, `sr-Latn`, as the Mac and the file names take it), a tab and the name
# in itself, English first. The scripts that make something per language read them here, so
# a language is added in that one list. pe-i18n's tests check that this reading of the list is the list.
#
#   scripts/languages.sh            en<TAB>English, de<TAB>Deutsch, ...
#   scripts/languages.sh --codes    en ca cs ... pt-BR pt ... sr-Latn ... on one line
set -euo pipefail
LIB="$(dirname "$0")/../core/crates/pe-i18n/src/lib.rs"
list=$(sed -n '/^pub const LANGUAGES/,/^];/s/^    ("\([a-zA-Z-]*\)", "\(.*\)"),$/\1	\2/p' "$LIB")
[ -n "$list" ] || { echo "No languages found in $LIB" >&2; exit 1; }
if [ "${1:-}" = "--codes" ]; then
    echo "$list" | cut -f1 | tr '\n' ' ' | sed 's/ $//'
    echo
else
    echo "$list"
fi
