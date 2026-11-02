@echo off
rem Builds the app and stages what the installer installs in dist\InboxClassic: InboxClassic.exe (the Rust core is
rem linked into it) and THIRD-PARTY-NOTICES.txt. WebView2 comes with Windows 11. dist\InboxClassic-win-x64.zip is
rem the same as a portable zip
setlocal
call "%~dp0win-build.cmd" || exit /b 1
cd /d "%~dp0.."
set OUT=dist\InboxClassic
if exist dist rmdir /s /q dist
mkdir %OUT% || exit /b 1
copy /y build\InboxClassic.exe %OUT%\ >nul || exit /b 1
call "%~dp0vcvars.cmd" >nul || exit /b 1
node "%~dp0notices.mjs" %OUT% build || exit /b 1
powershell -NoProfile -Command "Compress-Archive -Path '%OUT%' -DestinationPath 'dist\InboxClassic-win-x64.zip' -Force" || exit /b 1
echo dist\InboxClassic-win-x64.zip
