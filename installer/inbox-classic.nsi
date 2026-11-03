; The installer of Inbox Classic, built with NSIS 3.08 or newer (makensis runs on Windows, macOS and Linux):
;
;   makensis -NOCD -DVERSION=0.1.0 -DSTAGING=dist/InboxClassic -DOUTFILE=dist/InboxClassic-Setup.exe \
;            [-DSIGN] installer/inbox-classic.nsi
;
; Run it from the root of the repository, -NOCD keeps the relative paths there. STAGING holds what gets installed:
; InboxClassic.exe and THIRD-PARTY-NOTICES.txt (scripts/win-package.cmd makes it).
; With SIGN the uninstaller and the installer are signed while they are built, with scripts/sign-win.sh.
;
; Updates: every version installs to the same per-user folder and registry keys, so running the installer of a
; newer version upgrades in place. A running copy is closed first, and the mail store in
; %LOCALAPPDATA%\InboxClassic stays.

Unicode true
ManifestDPIAware true
SetCompressor /SOLID lzma

!include MUI2.nsh
!include LogicLib.nsh
!include WordFunc.nsh
!include FileFunc.nsh

!ifndef VERSION
    !error "VERSION is not defined, pass -DVERSION=x.y.z"
!endif
!ifndef STAGING
    !error "STAGING is not defined, pass -DSTAGING=<folder with the files to install>"
!endif
!ifndef OUTFILE
    !define OUTFILE "InboxClassic-Setup.exe"
!endif

!define PRODUCT "Inbox Classic"
!define EXE "InboxClassic.exe"
!define PUBLISHER "Postal Systems OÜ"
!define HOMEPAGE "https://inboxclassic.com"
; the same keys for every version, this is how a newer installer finds the installed one
!define REGKEY "Software\Postal Systems\InboxClassic"
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\InboxClassic"
; a mail program Windows lists in Default apps, for mailto: links (the user chooses it there; Tools > Make Default
; Mail App opens that page)
!define CLIENTKEY "Software\Clients\Mail\${PRODUCT}"
!define MAILTOCLASS "InboxClassic.mailto"
; forward slashes work for makensis on every platform, and for the shell that runs the signing script
!define ROOT "${__FILEDIR__}/.."

!ifdef SIGN
    ; signs the uninstaller before it is packed into the installer, and the installer once it is written
    !uninstfinalize '"${ROOT}/scripts/sign-win.sh" "%1"' = 0
    !finalize '"${ROOT}/scripts/sign-win.sh" "%1"' = 0
!endif

Name "${PRODUCT}"
OutFile "${OUTFILE}"
; per user, no administrator rights needed
RequestExecutionLevel user
InstallDir "$LOCALAPPDATA\Programs\${PRODUCT}"
InstallDirRegKey HKCU "${REGKEY}" "InstallDir"
BrandingText "${PRODUCT} ${VERSION}"

VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${PRODUCT}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "CompanyName" "${PUBLISHER}"
VIAddVersionKey "FileDescription" "${PRODUCT} Setup"
VIAddVersionKey "LegalCopyright" "Copyright (c) ${PUBLISHER}"

Var InstalledVersion
Var WelcomeText

!define MUI_ABORTWARNING
; the app's own icon for the installer and the uninstaller (makensis runs from the repository root, -NOCD)
!define MUI_ICON "app/res/app.ico"
!define MUI_UNICON "app/res/app.ico"
!define MUI_WELCOMEPAGE_TEXT "$WelcomeText"
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Start ${PRODUCT}"

!insertmacro MUI_PAGE_WELCOME
; an upgrade goes where the installed version is, the folder is chosen on the first install only
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipDirectoryOnUpgrade
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Closes a running Inbox Classic of this user. taskkill without /f sends WM_CLOSE, so the app closes its store
; and logs out of its servers. A running exe can not be opened for writing (it can be renamed, so that is no test);
; after 15 seconds it is ended forcefully
!macro CLOSE_APP prefix
    Function ${prefix}IsRunning
        StrCpy $3 0
        ${If} ${FileExists} "$INSTDIR\${EXE}"
            ClearErrors
            FileOpen $2 "$INSTDIR\${EXE}" a
            ${If} ${Errors}
                StrCpy $3 1
            ${Else}
                FileClose $2
            ${EndIf}
        ${EndIf}
    FunctionEnd

    Function ${prefix}CloseApp
        Call ${prefix}IsRunning
        ${If} $3 = 0
            Return
        ${EndIf}
        ReadEnvStr $0 USERNAME
        nsExec::Exec '"$SYSDIR\taskkill.exe" /fi "USERNAME eq $0" /im ${EXE}'
        Pop $1
        StrCpy $1 0
        ${Do}
            Sleep 500
            Call ${prefix}IsRunning
            ${IfThen} $3 = 0 ${|} ${Break} ${|}
            IntOp $1 $1 + 1
            ${If} $1 = 30
                nsExec::Exec '"$SYSDIR\taskkill.exe" /f /fi "USERNAME eq $0" /im ${EXE}'
                Pop $2
            ${ElseIf} $1 > 40
                MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "${PRODUCT} is still running. Close it and try again." /SD IDCANCEL IDRETRY +2
                Abort
                StrCpy $1 0
            ${EndIf}
        ${Loop}
    FunctionEnd
!macroend
!insertmacro CLOSE_APP ""
!insertmacro CLOSE_APP "un."

Function .onInit
    ReadRegStr $InstalledVersion HKCU "${UNINSTKEY}" "DisplayVersion"
    ${If} $InstalledVersion == ""
        StrCpy $WelcomeText "This will install ${PRODUCT} ${VERSION}, an e-mail program.$\r$\n$\r$\nNo administrator rights are needed, it is installed for your account only."
        Return
    ${EndIf}
    ; 0 the same version, 1 this one is newer, 2 the installed one is newer
    ${VersionCompare} "${VERSION}" "$InstalledVersion" $0
    ${If} $0 = 2
        MessageBox MB_YESNO|MB_ICONQUESTION "${PRODUCT} $InstalledVersion is installed, which is newer than ${VERSION}. Install the older version anyway?" /SD IDNO IDYES +2
        Abort
    ${EndIf}
    ${If} $0 = 0
        StrCpy $WelcomeText "${PRODUCT} ${VERSION} is installed already. This will install it again.$\r$\n$\r$\nYour accounts and mail are kept."
    ${Else}
        StrCpy $WelcomeText "This will update ${PRODUCT} $InstalledVersion to ${VERSION}.$\r$\n$\r$\nIf it is running it is closed first. Your accounts and mail are kept."
    ${EndIf}
FunctionEnd

Function SkipDirectoryOnUpgrade
    ${If} $InstalledVersion != ""
        Abort
    ${EndIf}
FunctionEnd

Section "Install"
    Call CloseApp
    SetOutPath "$INSTDIR"
    ; a backslash before the wildcard, makensis on Windows does not match "dir/*" and on other systems it converts it
    File /r "${STAGING}\*"
    WriteUninstaller "$INSTDIR\uninstall.exe"

    CreateShortcut "$SMPROGRAMS\${PRODUCT}.lnk" "$INSTDIR\${EXE}"

    WriteRegStr HKCU "${REGKEY}" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "${REGKEY}" "Version" "${VERSION}"
    WriteRegStr HKCU "${UNINSTKEY}" "DisplayName" "${PRODUCT}"
    WriteRegStr HKCU "${UNINSTKEY}" "DisplayVersion" "${VERSION}"
    WriteRegStr HKCU "${UNINSTKEY}" "Publisher" "${PUBLISHER}"
    WriteRegStr HKCU "${UNINSTKEY}" "URLInfoAbout" "${HOMEPAGE}"
    WriteRegStr HKCU "${UNINSTKEY}" "DisplayIcon" "$INSTDIR\${EXE}"
    WriteRegStr HKCU "${UNINSTKEY}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKCU "${UNINSTKEY}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
    WriteRegDWORD HKCU "${UNINSTKEY}" "NoModify" 1
    WriteRegDWORD HKCU "${UNINSTKEY}" "NoRepair" 1
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    WriteRegDWORD HKCU "${UNINSTKEY}" "EstimatedSize" $0

    ; mailto: links, should the user choose it for them
    WriteRegStr HKCU "Software\Classes\${MAILTOCLASS}" "" "URL:MailTo Protocol"
    WriteRegStr HKCU "Software\Classes\${MAILTOCLASS}" "URL Protocol" ""
    WriteRegStr HKCU "Software\Classes\${MAILTOCLASS}\DefaultIcon" "" "$INSTDIR\${EXE},0"
    WriteRegStr HKCU "Software\Classes\${MAILTOCLASS}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
    WriteRegStr HKCU "${CLIENTKEY}" "" "${PRODUCT}"
    WriteRegStr HKCU "${CLIENTKEY}\Capabilities" "ApplicationName" "${PRODUCT}"
    WriteRegStr HKCU "${CLIENTKEY}\Capabilities" "ApplicationDescription" "A classic Windows email program."
    WriteRegStr HKCU "${CLIENTKEY}\Capabilities" "ApplicationIcon" "$INSTDIR\${EXE},0"
    WriteRegStr HKCU "${CLIENTKEY}\Capabilities\URLAssociations" "mailto" "${MAILTOCLASS}"
    WriteRegStr HKCU "${CLIENTKEY}\shell\open\command" "" '"$INSTDIR\${EXE}"'
    WriteRegStr HKCU "Software\RegisteredApplications" "${PRODUCT}" "${CLIENTKEY}\Capabilities"
SectionEnd

Section "Uninstall"
    Call un.CloseApp
    ; only what the installer put there, the folder may hold files of the user
    Delete "$INSTDIR\${EXE}"
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\THIRD-PARTY-NOTICES.txt"
    RMDir "$INSTDIR"

    Delete "$SMPROGRAMS\${PRODUCT}.lnk"
    DeleteRegValue HKCU "Software\RegisteredApplications" "${PRODUCT}"
    DeleteRegKey HKCU "${CLIENTKEY}"
    DeleteRegKey HKCU "Software\Classes\${MAILTOCLASS}"
    DeleteRegKey HKCU "${UNINSTKEY}"
    DeleteRegKey HKCU "${REGKEY}"
    DeleteRegKey /ifempty HKCU "Software\Postal Systems"

    ; the cache of the message preview (app/src/preview.cpp)
    RMDir /r "$LOCALAPPDATA\InboxClassic\WebView2"
    ; the saved passwords stay in the Credential Manager under "InboxClassic", named after a random ID of the
    ; removed store: no other store can use them
    MessageBox MB_YESNO|MB_ICONQUESTION "Also remove the accounts and the mail Inbox Classic keeps on this computer? The mail on the servers stays." /SD IDNO IDNO +2
    RMDir /r "$LOCALAPPDATA\InboxClassic"
SectionEnd
