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
; .eml files, listed in Open With and in Default Apps
!define EMLCLASS "InboxClassic.eml"
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
!define MUI_FINISHPAGE_RUN_TEXT "$(StartApp)"
; the language asked for first, Windows' own preselected; remembered for the next update and for the uninstaller
!define MUI_LANGDLL_REGISTRY_ROOT HKCU
!define MUI_LANGDLL_REGISTRY_KEY "${REGKEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "InstallerLanguage"
!define MUI_LANGDLL_WINDOWTITLE "${PRODUCT}"

!insertmacro MUI_PAGE_WELCOME
; an upgrade goes where the installed version is, the folder is chosen on the first install only
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipDirectoryOnUpgrade
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; the languages there are catalogs of (core/locales), English first
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Estonian"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_RESERVEFILE_LANGDLL

; the installer's own words in each language; ${PRODUCT} and the versions are filled in
; the code of the language chosen for the installer, the app's language on a first install (app/src/options.cpp)
LangString LanguageCode ${LANG_ENGLISH} "en"
LangString LanguageCode ${LANG_GERMAN} "de"
LangString LanguageCode ${LANG_ESTONIAN} "et"
LangString LanguageCode ${LANG_SPANISH} "es"
LangString LanguageCode ${LANG_FRENCH} "fr"

LangString StartApp ${LANG_ENGLISH} "Start ${PRODUCT}"
LangString StartApp ${LANG_GERMAN} "${PRODUCT} starten"
LangString StartApp ${LANG_ESTONIAN} "Käivita ${PRODUCT}"
LangString StartApp ${LANG_SPANISH} "Iniciar ${PRODUCT}"
LangString StartApp ${LANG_FRENCH} "Démarrer ${PRODUCT}"

LangString WelcomeNew ${LANG_ENGLISH} "This will install ${PRODUCT} ${VERSION}, an e-mail program.$\r$\n$\r$\nNo administrator rights are needed, it is installed for your account only."
LangString WelcomeNew ${LANG_GERMAN} "Hiermit wird ${PRODUCT} ${VERSION} installiert, ein E-Mail-Programm.$\r$\n$\r$\nAdministratorrechte sind nicht nötig, es wird nur für Ihr Konto installiert."
LangString WelcomeNew ${LANG_ESTONIAN} "See installib meiliprogrammi ${PRODUCT} ${VERSION}.$\r$\n$\r$\nAdministraatori õigusi pole vaja, see installitakse ainult teie kontole."
LangString WelcomeNew ${LANG_SPANISH} "Se instalará ${PRODUCT} ${VERSION}, un programa de correo electrónico.$\r$\n$\r$\nNo se necesitan derechos de administrador; se instala solo para su cuenta."
LangString WelcomeNew ${LANG_FRENCH} "Ceci va installer ${PRODUCT} ${VERSION}, un programme de messagerie.$\r$\n$\r$\nAucun droit d'administrateur n'est nécessaire, il est installé pour votre compte uniquement."

LangString WelcomeSame ${LANG_ENGLISH} "${PRODUCT} ${VERSION} is installed already. This will install it again.$\r$\n$\r$\nYour accounts and mail are kept."
LangString WelcomeSame ${LANG_GERMAN} "${PRODUCT} ${VERSION} ist bereits installiert. Hiermit wird es erneut installiert.$\r$\n$\r$\nIhre Konten und E-Mails bleiben erhalten."
LangString WelcomeSame ${LANG_ESTONIAN} "${PRODUCT} ${VERSION} on juba installitud. See installib selle uuesti.$\r$\n$\r$\nTeie kontod ja kirjad jäävad alles."
LangString WelcomeSame ${LANG_SPANISH} "${PRODUCT} ${VERSION} ya está instalado. Se instalará de nuevo.$\r$\n$\r$\nSus cuentas y su correo se conservan."
LangString WelcomeSame ${LANG_FRENCH} "${PRODUCT} ${VERSION} est déjà installé. Ceci va le réinstaller.$\r$\n$\r$\nVos comptes et votre courrier sont conservés."

LangString WelcomeUpdate ${LANG_ENGLISH} "This will update ${PRODUCT} $InstalledVersion to ${VERSION}.$\r$\n$\r$\nIf it is running it is closed first. Your accounts and mail are kept."
LangString WelcomeUpdate ${LANG_GERMAN} "Hiermit wird ${PRODUCT} $InstalledVersion auf ${VERSION} aktualisiert.$\r$\n$\r$\nLäuft es, wird es zuerst geschlossen. Ihre Konten und E-Mails bleiben erhalten."
LangString WelcomeUpdate ${LANG_ESTONIAN} "See uuendab programmi ${PRODUCT} versioonist $InstalledVersion versioonile ${VERSION}.$\r$\n$\r$\nKui see töötab, suletakse see enne. Teie kontod ja kirjad jäävad alles."
LangString WelcomeUpdate ${LANG_SPANISH} "Se actualizará ${PRODUCT} $InstalledVersion a ${VERSION}.$\r$\n$\r$\nSi está abierto, primero se cierra. Sus cuentas y su correo se conservan."
LangString WelcomeUpdate ${LANG_FRENCH} "Ceci va mettre à jour ${PRODUCT} $InstalledVersion vers ${VERSION}.$\r$\n$\r$\nS'il est ouvert, il est d'abord fermé. Vos comptes et votre courrier sont conservés."

LangString OlderAsk ${LANG_ENGLISH} "${PRODUCT} $InstalledVersion is installed, which is newer than ${VERSION}. Install the older version anyway?"
LangString OlderAsk ${LANG_GERMAN} "${PRODUCT} $InstalledVersion ist installiert und neuer als ${VERSION}. Die ältere Version trotzdem installieren?"
LangString OlderAsk ${LANG_ESTONIAN} "Installitud on ${PRODUCT} $InstalledVersion, mis on uuem kui ${VERSION}. Kas installida vanem versioon siiski?"
LangString OlderAsk ${LANG_SPANISH} "Está instalado ${PRODUCT} $InstalledVersion, que es más reciente que ${VERSION}. ¿Instalar de todos modos la versión anterior?"
LangString OlderAsk ${LANG_FRENCH} "${PRODUCT} $InstalledVersion est installé et plus récent que ${VERSION}. Installer quand même l'ancienne version ?"

LangString StillRunning ${LANG_ENGLISH} "${PRODUCT} is still running. Close it and try again."
LangString StillRunning ${LANG_GERMAN} "${PRODUCT} läuft noch. Schließen Sie es und versuchen Sie es erneut."
LangString StillRunning ${LANG_ESTONIAN} "${PRODUCT} töötab endiselt. Sulgege see ja proovige uuesti."
LangString StillRunning ${LANG_SPANISH} "${PRODUCT} sigue abierto. Ciérrelo y vuelva a intentarlo."
LangString StillRunning ${LANG_FRENCH} "${PRODUCT} est toujours ouvert. Fermez-le et réessayez."

LangString RemoveMailAsk ${LANG_ENGLISH} "Also remove the accounts and the mail ${PRODUCT} keeps on this computer? The mail on the servers stays."
LangString RemoveMailAsk ${LANG_GERMAN} "Auch die Konten und E-Mails entfernen, die ${PRODUCT} auf diesem Computer speichert? Die E-Mails auf den Servern bleiben."
LangString RemoveMailAsk ${LANG_ESTONIAN} "Kas eemaldada ka kontod ja kirjad, mida ${PRODUCT} selles arvutis hoiab? Serverites olevad kirjad jäävad alles."
LangString RemoveMailAsk ${LANG_SPANISH} "¿Quitar también las cuentas y el correo que ${PRODUCT} guarda en este equipo? El correo de los servidores se queda."
LangString RemoveMailAsk ${LANG_FRENCH} "Supprimer aussi les comptes et le courrier qu'${PRODUCT} garde sur cet ordinateur ? Le courrier sur les serveurs reste."

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
                MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "$(StillRunning)" /SD IDCANCEL IDRETRY +2
                Abort
                StrCpy $1 0
            ${EndIf}
        ${Loop}
    FunctionEnd
!macroend
!insertmacro CLOSE_APP ""
!insertmacro CLOSE_APP "un."

Function .onInit
    ; not asked in a silent install, which stays in Windows' language (or the one chosen before)
    ${IfNot} ${Silent}
        !insertmacro MUI_LANGDLL_DISPLAY
    ${EndIf}
    ReadRegStr $InstalledVersion HKCU "${UNINSTKEY}" "DisplayVersion"
    ${If} $InstalledVersion == ""
        StrCpy $WelcomeText "$(WelcomeNew)"
        Return
    ${EndIf}
    ; 0 the same version, 1 this one is newer, 2 the installed one is newer
    ${VersionCompare} "${VERSION}" "$InstalledVersion" $0
    ${If} $0 = 2
        MessageBox MB_YESNO|MB_ICONQUESTION "$(OlderAsk)" /SD IDNO IDYES +2
        Abort
    ${EndIf}
    ${If} $0 = 0
        StrCpy $WelcomeText "$(WelcomeSame)"
    ${Else}
        StrCpy $WelcomeText "$(WelcomeUpdate)"
    ${EndIf}
FunctionEnd

Function un.onInit
    ; the language the installer was run in
    !insertmacro MUI_UNGETLANGUAGE
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
    ; the app in the language chosen for the installer, on a first install only: never over a language the user chose
    ; in Options, and not in a silent install, where nobody chose one (the app follows Windows then)
    ${If} $InstalledVersion == ""
    ${AndIfNot} ${Silent}
        ClearErrors
        ReadRegStr $0 HKCU "${REGKEY}" "Language"
        ${If} ${Errors}
            WriteRegStr HKCU "${REGKEY}" "Language" "$(LanguageCode)"
        ${EndIf}
    ${EndIf}
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
    ; .eml files: a message window of the file (app/src/main.cpp), in Open With and, should the user choose it, by
    ; default; never taken over from the program that opens them now
    WriteRegStr HKCU "Software\Classes\${EMLCLASS}" "" "E-mail Message"
    WriteRegStr HKCU "Software\Classes\${EMLCLASS}\DefaultIcon" "" "$INSTDIR\${EXE},0"
    WriteRegStr HKCU "Software\Classes\${EMLCLASS}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
    WriteRegStr HKCU "Software\Classes\.eml\OpenWithProgids" "${EMLCLASS}" ""
    WriteRegStr HKCU "${CLIENTKEY}\Capabilities\FileAssociations" ".eml" "${EMLCLASS}"
    WriteRegStr HKCU "Software\RegisteredApplications" "${PRODUCT}" "${CLIENTKEY}\Capabilities"
    ; Explorer reads the associations again
    System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
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
    DeleteRegValue HKCU "Software\Classes\.eml\OpenWithProgids" "${EMLCLASS}"
    DeleteRegKey /ifempty HKCU "Software\Classes\.eml\OpenWithProgids"
    DeleteRegKey /ifempty HKCU "Software\Classes\.eml"
    DeleteRegKey HKCU "Software\Classes\${EMLCLASS}"
    System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
    DeleteRegKey HKCU "${UNINSTKEY}"
    DeleteRegKey HKCU "${REGKEY}"
    DeleteRegKey /ifempty HKCU "Software\Postal Systems"

    ; the cache of the message preview (app/src/preview.cpp)
    RMDir /r "$LOCALAPPDATA\InboxClassic\WebView2"
    ; the saved passwords stay in the Credential Manager under "InboxClassic", named after a random ID of the
    ; removed store: no other store can use them
    MessageBox MB_YESNO|MB_ICONQUESTION "$(RemoveMailAsk)" /SD IDNO IDNO +2
    RMDir /r "$LOCALAPPDATA\InboxClassic"
SectionEnd
