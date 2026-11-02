#!/usr/bin/env bash
# Takes a screenshot of the app window on the Windows machine and copies it here: scripts/win-screenshot.sh out.png
# DESKTOP=1 takes the whole desktop instead. Needs a logged in, unlocked desktop session
set -euo pipefail
. "$(dirname "$0")/win-env.sh"
OUT=${1:-screenshot.png}
FLAG="${DESKTOP:+ -Desktop}"
ssh "$WIN_HOST" "del $WIN_DIR\\shot.png >nul 2>&1 & schtasks /create /tn InboxClassicShot /tr \"powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $WIN_DIR\\scripts\\screenshot.ps1 $WIN_DIR\\shot.png$FLAG\" /sc once /st 23:59 /it /f >nul && schtasks /run /tn InboxClassicShot >nul"
for _ in $(seq 1 20); do
    if scp -q "$WIN_HOST:$WIN_DIR_FWD/shot.png" "$OUT" 2>/dev/null; then
        echo "$OUT"
        exit 0
    fi
    sleep 1
done
echo "no screenshot, is a desktop session logged in and not locked?" >&2
exit 1
