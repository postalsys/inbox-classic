; Generated from pe_i18n::LANGUAGES and core/locales by core/crates/pe-ffi/build.rs, do not edit

; the languages there are catalogs of, English first; one NSIS has no language file of installs in English
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Estonian"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "French"

; the code of the language chosen for the installer, the app's language on a first install (app/src/options.cpp)
LangString LanguageCode ${LANG_ENGLISH} "en"
LangString LanguageCode ${LANG_GERMAN} "de"
LangString LanguageCode ${LANG_ESTONIAN} "et"
LangString LanguageCode ${LANG_SPANISH} "es"
LangString LanguageCode ${LANG_FRENCH} "fr"

LangString StartApp ${LANG_ENGLISH} "Start Inbox Classic"
LangString StartApp ${LANG_GERMAN} "Inbox Classic starten"
LangString StartApp ${LANG_ESTONIAN} "Käivita Inbox Classic"
LangString StartApp ${LANG_SPANISH} "Iniciar Inbox Classic"
LangString StartApp ${LANG_FRENCH} "Démarrer Inbox Classic"

LangString WelcomeNew ${LANG_ENGLISH} "This will install Inbox Classic ${VERSION}, an e-mail program.$\r$\n$\r$\nNo administrator rights are needed, it is installed for your account only."
LangString WelcomeNew ${LANG_GERMAN} "Hiermit wird Inbox Classic ${VERSION} installiert, ein E-Mail-Programm.$\r$\n$\r$\nAdministratorrechte sind nicht nötig, es wird nur für Ihr Konto installiert."
LangString WelcomeNew ${LANG_ESTONIAN} "See installib meiliprogrammi Inbox Classic ${VERSION}.$\r$\n$\r$\nAdministraatori õigusi pole vaja, see installitakse ainult teie kontole."
LangString WelcomeNew ${LANG_SPANISH} "Se instalará Inbox Classic ${VERSION}, un programa de correo electrónico.$\r$\n$\r$\nNo se necesitan derechos de administrador; se instala solo para su cuenta."
LangString WelcomeNew ${LANG_FRENCH} "Ceci va installer Inbox Classic ${VERSION}, un programme de messagerie.$\r$\n$\r$\nAucun droit d'administrateur n'est nécessaire, il est installé pour votre compte uniquement."

LangString WelcomeSame ${LANG_ENGLISH} "Inbox Classic ${VERSION} is installed already. This will install it again.$\r$\n$\r$\nYour accounts and mail are kept."
LangString WelcomeSame ${LANG_GERMAN} "Inbox Classic ${VERSION} ist bereits installiert. Hiermit wird es erneut installiert.$\r$\n$\r$\nIhre Konten und E-Mails bleiben erhalten."
LangString WelcomeSame ${LANG_ESTONIAN} "Inbox Classic ${VERSION} on juba installitud. See installib selle uuesti.$\r$\n$\r$\nTeie kontod ja kirjad jäävad alles."
LangString WelcomeSame ${LANG_SPANISH} "Inbox Classic ${VERSION} ya está instalado. Se instalará de nuevo.$\r$\n$\r$\nSus cuentas y su correo se conservan."
LangString WelcomeSame ${LANG_FRENCH} "Inbox Classic ${VERSION} est déjà installé. Ceci va le réinstaller.$\r$\n$\r$\nVos comptes et votre courrier sont conservés."

LangString WelcomeUpdate ${LANG_ENGLISH} "This will update Inbox Classic $InstalledVersion to ${VERSION}.$\r$\n$\r$\nIf it is running it is closed first. Your accounts and mail are kept."
LangString WelcomeUpdate ${LANG_GERMAN} "Hiermit wird Inbox Classic $InstalledVersion auf ${VERSION} aktualisiert.$\r$\n$\r$\nLäuft es, wird es zuerst geschlossen. Ihre Konten und E-Mails bleiben erhalten."
LangString WelcomeUpdate ${LANG_ESTONIAN} "See uuendab programmi Inbox Classic versioonist $InstalledVersion versioonile ${VERSION}.$\r$\n$\r$\nKui see töötab, suletakse see enne. Teie kontod ja kirjad jäävad alles."
LangString WelcomeUpdate ${LANG_SPANISH} "Se actualizará Inbox Classic $InstalledVersion a ${VERSION}.$\r$\n$\r$\nSi está abierto, primero se cierra. Sus cuentas y su correo se conservan."
LangString WelcomeUpdate ${LANG_FRENCH} "Ceci va mettre à jour Inbox Classic $InstalledVersion vers ${VERSION}.$\r$\n$\r$\nS'il est ouvert, il est d'abord fermé. Vos comptes et votre courrier sont conservés."

LangString OlderAsk ${LANG_ENGLISH} "Inbox Classic $InstalledVersion is installed, which is newer than ${VERSION}. Install the older version anyway?"
LangString OlderAsk ${LANG_GERMAN} "Inbox Classic $InstalledVersion ist installiert und neuer als ${VERSION}. Die ältere Version trotzdem installieren?"
LangString OlderAsk ${LANG_ESTONIAN} "Installitud on Inbox Classic $InstalledVersion, mis on uuem kui ${VERSION}. Kas installida vanem versioon siiski?"
LangString OlderAsk ${LANG_SPANISH} "Está instalado Inbox Classic $InstalledVersion, que es más reciente que ${VERSION}. ¿Instalar de todos modos la versión anterior?"
LangString OlderAsk ${LANG_FRENCH} "Inbox Classic $InstalledVersion est installé et plus récent que ${VERSION}. Installer quand même l'ancienne version ?"

LangString StillRunning ${LANG_ENGLISH} "Inbox Classic is still running. Close it and try again."
LangString StillRunning ${LANG_GERMAN} "Inbox Classic läuft noch. Schließen Sie es und versuchen Sie es erneut."
LangString StillRunning ${LANG_ESTONIAN} "Inbox Classic töötab endiselt. Sulgege see ja proovige uuesti."
LangString StillRunning ${LANG_SPANISH} "Inbox Classic sigue abierto. Ciérrelo y vuelva a intentarlo."
LangString StillRunning ${LANG_FRENCH} "Inbox Classic est toujours ouvert. Fermez-le et réessayez."

LangString RemoveMailAsk ${LANG_ENGLISH} "Also remove the accounts and the mail Inbox Classic keeps on this computer? The mail on the servers stays."
LangString RemoveMailAsk ${LANG_GERMAN} "Auch die Konten und E-Mails entfernen, die Inbox Classic auf diesem Computer speichert? Die E-Mails auf den Servern bleiben."
LangString RemoveMailAsk ${LANG_ESTONIAN} "Kas eemaldada ka kontod ja kirjad, mida Inbox Classic selles arvutis hoiab? Serverites olevad kirjad jäävad alles."
LangString RemoveMailAsk ${LANG_SPANISH} "¿Quitar también las cuentas y el correo que Inbox Classic guarda en este equipo? El correo de los servidores se queda."
LangString RemoveMailAsk ${LANG_FRENCH} "Supprimer aussi les comptes et le courrier qu'Inbox Classic garde sur cet ordinateur ? Le courrier sur les serveurs reste."
