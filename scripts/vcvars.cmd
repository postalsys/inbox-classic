@echo off
rem Sets up the C++ tools of Visual Studio 2022 (Build Tools or a full edition, they bring CMake and Ninja) and cargo
for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set VSDIR=%%i
if not defined VSDIR (
    echo Visual Studio with the C++ tools was not found
    exit /b 1
)
call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
set PATH=%USERPROFILE%\.cargo\bin;%PATH%
