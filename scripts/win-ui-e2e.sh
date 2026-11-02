#!/usr/bin/env bash
# Runs the UI end-to-end test (scripts/ui-e2e.ps1) against the built app on the desktop of the Windows machine, through
# an interactive scheduled task, and copies its log and screenshots to build/ui-e2e here. Build first with
# scripts/win-build.sh. Needs a logged in, unlocked desktop session
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/win-env.sh
win_sync
ssh "$WIN_HOST" "cd $WIN_DIR\\core\\e2e && npm ci --no-audit --no-fund --silent"
ssh "$WIN_HOST" "taskkill /im PostalExpress.exe /f >nul 2>&1 & del /q $WIN_DIR\\build\\ui-e2e\\result.txt >nul 2>&1 & schtasks /create /tn PostalExpressUiTest /tr \"powershell -NoProfile -ExecutionPolicy Bypass -File $WIN_DIR\\scripts\\ui-e2e.ps1\" /sc once /st 23:59 /it /f >nul && schtasks /run /tn PostalExpressUiTest >nul"
# one session that waits on the Windows side for the result, up to six minutes
result=$(ssh "$WIN_HOST" "powershell -NoProfile -Command \"\$f='$WIN_DIR\\build\\ui-e2e\\result.txt'; for (\$i = 0; \$i -lt 360 -and -not (Test-Path \$f); \$i++) { Start-Sleep 1 }; if (Test-Path \$f) { (Get-Content \$f).Trim() }\" & schtasks /delete /tn PostalExpressUiTest /f >nul" | tr -d '\r' || true)
rm -rf build/ui-e2e && mkdir -p build/ui-e2e
[ -n "$result" ] || ssh "$WIN_HOST" "del /q $WIN_DIR\\build\\ui-e2e\\log.txt >nul 2>&1"
scp -q "$WIN_HOST:$WIN_DIR_FWD/build/ui-e2e/*.png" "$WIN_HOST:$WIN_DIR_FWD/build/ui-e2e/log.txt" build/ui-e2e/ 2>/dev/null || true
cat build/ui-e2e/log.txt 2>/dev/null || true
if [ -z "$result" ]; then
    # no result at all: the script may not even parse (then it writes no log), or there is no desktop
    ssh "$WIN_HOST" "powershell -NoProfile -Command \"\$e = \$null; [void][System.Management.Automation.Language.Parser]::ParseFile('$WIN_DIR\\scripts\\ui-e2e.ps1', [ref]\$null, [ref]\$e); \$e | ForEach-Object { 'parse error, line ' + \$_.Extent.StartLineNumber + ': ' + \$_.Message }\""
    echo "no result, is a desktop session logged in and not locked?"
else
    echo "$result"
fi
[ "$result" = passed ]
