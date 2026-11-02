@echo off
rem Builds the Rust core and the app, run on Windows (scripts/win-build.sh calls it over SSH)
setlocal
call "%~dp0vcvars.cmd" || exit /b 1
cd /d "%~dp0.."
rem a running copy holds the exe open, the link would fail
taskkill /im InboxClassic.exe /f >nul 2>&1 && ping -n 2 127.0.0.1 >nul
cmake -S app -B build -G Ninja -DCMAKE_BUILD_TYPE=Release || exit /b 1
cmake --build build || exit /b 1
