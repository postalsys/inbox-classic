#!/usr/bin/env bash
# Copies the sources to the Windows build machine and builds them there with MSVC and cargo, gives build\InboxClassic.exe
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/win-env.sh
win_sync
ssh "$WIN_HOST" "$WIN_DIR\\scripts\\win-build.cmd"
