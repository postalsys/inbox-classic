#!/usr/bin/env bash
# Runs the UI end-to-end test of the Mac app (mac/Sources/InboxClassic/UITest.swift): builds the app with the test in
# its bundle, then runs the test, which starts ImapKit (core/e2e) and the app in its own process and drives its
# windows. The log and a screenshot of each step go to build/ui-e2e-mac. Needs a logged in session (the windows are
# real ones), Node.js and `npm ci` in core/e2e.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -z "${NO_BUILD:-}" ]; then
    TEST=1 scripts/mac-build.sh
fi
(cd core/e2e && [ -d node_modules/imapkit ] || npm ci --no-audit --no-fund --silent)
mkdir -p build/ui-e2e-mac
PE_REPO="$PWD" "build/mac/Inbox Classic.app/Contents/MacOS/InboxClassicUITest" --out "$PWD/build/ui-e2e-mac"
