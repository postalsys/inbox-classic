#!/usr/bin/env bash
# The rule that keeps the three apps in step: a change to what all of them show or do (the core's C API in
# core/include, the commands of core/commands.toml, the settings window of core/settings.toml, or the features of
# scripts/feature-map.mjs) changes the Windows app (app/), the Mac app (mac/) and the Linux app (linux/) in the same
# pull request. One that leaves a platform for later carries the label "shells: partial" and says in its description
# what is left for which platform.
#
#   scripts/check-shells.sh <base ref> [labels]      CI passes the PR's base branch and its labels, comma separated
set -euo pipefail
cd "$(dirname "$0")/.."
BASE=${1:?the base ref, e.g. origin/master}
LABELS=${2:-}
changed=$(git diff --name-only "$BASE"...HEAD)
# texts.h and languages.tsv list every message of the catalogs: a message the core alone writes (the apps show its
# words as they are) is no change to what the apps share, and one an app writes changes that app anyway
shared=$(grep -E '^(core/include/|core/(commands|settings)\.toml$|scripts/feature-map\.mjs$)' <<< "$changed" \
    | grep -vE '^core/include/(texts\.h|languages\.tsv)$' || true)
if [ -z "$shared" ]; then
    echo "Nothing all three apps share changed"
    exit 0
fi
echo "Changed for every app:"
printf '  %s\n' $shared
missing=()
for shell in app mac linux; do
    # a here-string, not a pipe: grep -q stops at the first match, and a long list written into a closed pipe fails
    # the pipeline under pipefail
    grep -q "^${shell}/" <<< "$changed" || missing+=("$shell/")
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
