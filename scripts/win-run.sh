#!/usr/bin/env bash
# Starts the built app on the desktop of the logged in user of the Windows machine (an SSH session has no desktop),
# through a scheduled task that runs interactively. Stops a running copy first
set -euo pipefail
. "$(dirname "$0")/win-env.sh"
# only this checkout's copy is closed: another checkout's UI test may be running
ssh -n "$WIN_HOST" "powershell -NoProfile -Command \"Get-Process InboxClassic -ErrorAction SilentlyContinue | Where-Object { \$_.Path -like '$WIN_DIR\\*' } | Stop-Process -Force; exit 0\""
ssh -n "$WIN_HOST" "schtasks /create /tn InboxClassicDev /tr $WIN_DIR\\build\\InboxClassic.exe /sc once /st 23:59 /it /f >nul && schtasks /run /tn InboxClassicDev"
