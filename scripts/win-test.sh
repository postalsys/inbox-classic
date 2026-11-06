#!/usr/bin/env bash
# Runs the Rust tests on the Windows build machine, arguments go to cargo test (e.g. scripts/win-test.sh -p pe-html)
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/win-env.sh
win_sync
ssh -n "$WIN_HOST" "$WIN_DIR\\scripts\\win-test.cmd $*"
