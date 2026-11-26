# Dot-sourced by the Windows test scripts before their first Add-Type. Windows PowerShell compiles Add-Type's C# with
# csc.exe into a DLL in %TEMP%; ESET on the build machine takes these helpers (SendInput, FindWindow) for a trojan
# (MSIL/Agent) and deletes them mid-run. This Add-Type compiles them in the checkout's build\ps-helpers instead,
# a folder under the build machine's performance exclusion (C:\Users\andri\src\*); %TEMP% is put back right after, so
# nothing else the scripts or the app do changes.
$script:helpersFolder = Join-Path $PSScriptRoot '..\build\ps-helpers'
New-Item -ItemType Directory -Force -Path $script:helpersFolder | Out-Null
function Add-Type {
    $temp, $tmp = $env:TEMP, $env:TMP
    $env:TEMP = $env:TMP = (Resolve-Path $script:helpersFolder).Path
    try {
        Microsoft.PowerShell.Utility\Add-Type @args
    } finally {
        $env:TEMP, $env:TMP = $temp, $tmp
    }
}
