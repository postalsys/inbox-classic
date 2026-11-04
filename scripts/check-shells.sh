#!/usr/bin/env bash
# The rule that keeps the three apps in step: a change to what all of them show or do (the core's C API in
# core/include, the commands of core/commands.toml, or the features of scripts/feature-map.mjs) changes the Windows
# app (app/), the Mac app (mac/) and the Linux app (linux/) in the same pull request. One that leaves a platform for
# later carries the label "shells: partial" and says in its description what is left for which platform.
#
#   scripts/check-shells.sh <base ref> [labels]      CI passes the PR's base branch and its labels, comma separated
set -euo pipefail
cd "$(dirname "$0")/.."
BASE=${1:?the base ref, e.g. origin/master}
LABELS=${2:-}
changed=$(git diff --name-only "$BASE"...HEAD)
shared=$(printf '%s\n' "$changed" | grep -E '^(core/include/|core/commands\.toml$|scripts/feature-map\.mjs$)' || true)
if [ -z "$shared" ]; then
    echo "Nothing all three apps share changed"
    exit 0
fi
echo "Changed for every app:"
printf '  %s\n' $shared
missing=()
for shell in app mac linux; do
    printf '%s\n' "$changed" | grep -q "^${shell}/" || missing+=("$shell/")
done
if [ ${#missing[@]} -eq 0 ]; then
    echo "app/, mac/ and linux/ changed with it"
    exit 0
fi
if [[ ",${LABELS}," == *",shells: partial,"* ]]; then
    echo "Not changed: ${missing[*]}; the PR is labelled \"shells: partial\", its description says what is left"
    exit 0
fi
echo "Not changed: ${missing[*]}. Make the same change there, or label the PR \"shells: partial\" and say in its" >&2
echo "description what is left for which platform." >&2
exit 1
