@echo off
rem Runs the Rust tests on Windows (scripts/win-test.sh calls it over SSH)
setlocal
call "%~dp0vcvars.cmd" || exit /b 1
cd /d "%~dp0..\core"
cargo test --workspace --locked %*
