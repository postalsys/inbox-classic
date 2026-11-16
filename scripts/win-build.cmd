@echo off
rem Builds the Rust core and the app, run on Windows (scripts/win-build.sh calls it over SSH)
setlocal
call "%~dp0vcvars.cmd" || exit /b 1
cd /d "%~dp0.."
rem a running copy holds the exe open, the link would fail: this checkout's own, never another checkout's (whose UI
rem test may be running)
powershell -NoProfile -Command "$own = Join-Path (Get-Location) 'build\InboxClassic.exe'; $p = Get-Process InboxClassic -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $own }; if ($p) { $p | Stop-Process -Force; Start-Sleep 1 }"
cmake -S app -B build -G Ninja -DCMAKE_BUILD_TYPE=Release || exit /b 1
cmake --build build || exit /b 1
