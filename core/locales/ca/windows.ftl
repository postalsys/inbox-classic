# Les paraules de les finestres pròpies de l’aplicació de Windows (app/src), identificadors que comencen per win-. Els
# marcadors entre { $claus } els omple l’aplicació; un & marca la lletra d’un menú o d’un botó (&& és un signe &).

## La finestra principal

# review: new
win-still-running-detail = Inbox Classic continua comprovant si hi ha correu nou en segon pla. Feu clic a la icona per obrir-lo. Per sortir, feu clic amb el botó dret a la icona i feu servir el seu menú.
# review: new
win-default-app-not-installed = Aquesta còpia d’Inbox Classic no s’ha instal·lat, per això Windows no la mostra com a aplicació de correu. Instal·leu-la per poder-la triar.
# review: new
win-default-app-settings = Windows obrirà la configuració d’Aplicacions predeterminades. Trieu Inbox Classic per obrir els enllaços MAILTO.
# review: new
win-no-unread = Cap missatge sense llegir
# review: new
win-unread-messages = { $count ->
    [one] 1 missatge sense llegir
   *[other] { $count } missatges sense llegir
}
# review: new
win-print-failed = No s’ha pogut imprimir el missatge.
# review: new
win-print-title-of = Imprimeix: { $subject }
# review: new
win-no-bodies = No es pot mostrar el cos dels missatges.
# review: new
win-webview-failed = No s’ha pogut crear el WebView2.
# review: new
win-webview-missing = L’entorn d’execució WebView2 no està disponible.
# review: new
win-list-loading = S'està carregant...

## Botons i paraules de moltes finestres

# review: new
win-delete-button = &Suprimeix
# review: new
win-find-label = &Cerca:
# review: new
win-save-as-button = Desa &com a...
# review: new
win-too-many-files = Massa fitxers alhora: trieu-ne menys.

## La Safata de sortida


## La finestra de redacció

# review: new
win-editor-failed = No es poden escriure missatges.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+clic per obrir)
# review: new
win-format-bold = Negreta ({ $ctrl }+B)
# review: new
win-format-italic = Cursiva ({ $ctrl }+I)
# review: new
win-format-underline = Subratllat ({ $ctrl }+U)
# review: new
win-format-link = Hiperenllaç ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = C&co
# review: new
win-signature-title = Signatura: { $account }

## Les carpetes, la llista de missatges i la subfinestra de lectura

# review: new
win-search-found-all = { $count ->
    [0] Cap resultat per a «{ $words }» a totes les carpetes
    [one] { $count } resultat per a «{ $words }» a totes les carpetes
   *[other] { $count } resultats per a «{ $words }» a totes les carpetes
}
# review: new
win-search-found-in = { $count ->
    [0] Cap resultat per a «{ $words }» a la carpeta { $folder }
    [one] { $count } resultat per a «{ $words }» a la carpeta { $folder }
   *[other] { $count } resultats per a «{ $words }» a la carpeta { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] encara s’està indexant el text de { $count } missatge
   *[other] encara s’està indexant el text de { $count } missatges
}
# review: new
win-no-match-indexing = { $count ->
    [one] Encara s’està indexant el text de { $count } missatge, per això aviat se’n poden trobar més.
   *[other] Encara s’està indexant el text de { $count } missatges, per això aviat se’n poden trobar més.
}
# review: new
win-files = { $count ->
    [one] { $count } fitxer
   *[other] { $count } fitxers
}
# review: new
win-click-to-retry = Feu clic aquí per tornar-ho a provar.
# review: new
win-save-attachments = De&sa els fitxers adjunts...
# review: new
win-files-not-saved = No s’han pogut desar { $failed } dels { $count } fitxers.
# review: new
win-new-folder-in-highlighted = La carpeta nova es crearà dins de la carpeta seleccionada.
# review: new
win-delete-folder-ask = Voleu suprimir la carpeta «{ $folder }» amb els seus missatges i les carpetes que conté? També se suprimeix al servidor.
# review: new
win-rename = Canvia el &nom...
# review: new
win-messages-not-saved = No s’han pogut desar els missatges.
# review: new
win-messages-not-forwarded = No s’han pogut reenviar els missatges.

## Comptes

# review: new
win-sign-in-google = Inicia la sessió amb Google
# review: new
win-sign-in-microsoft = Inicia la sessió amb Microsoft
# review: new
win-next = &Següent >
# review: new
win-your-account = el vostre compte
# review: new
win-browser-sign-in = (inici de sessió al navegador)
# review: new
win-add = &Afegeix...
# review: new
win-properties-button = &Propietats...
# review: new
win-signature-button = Si&gnatura...
# review: new
win-sign-in-apps-button = Aplicacions d’&inici de sessió...

## Agents d’IA

# review: new
win-dont-allow = &No ho permetis
# review: new
win-col-address = Adreça
# review: new
win-never-written-to = Mai no s’hi ha escrit
# review: new
win-book-find-label = Escriviu un nom o una adreça electrònica:
# review: new
win-send = &Envia
# review: new
win-dont-send = &No l’enviïs
# review: new
win-forget-program-ask = Voleu eliminar aquest programa, els seus permisos i l’historial d’activitat dels seus agents? Se us tornarà a demanar permís la propera vegada que es connecti.
# review: new
win-clear-log-ask = Voleu esborrar l’historial d’activitat dels agents? Això no desfarà els canvis que han fet els agents.
# review: new
win-agent-programs = &Programes els agents dels quals han demanat accés al vostre correu:
# review: new
win-change = &Canvia...
# review: new
win-what-agents-did = &Activitat dels agents:
# review: new
win-how-to-connect = Com connectar un agent

## Aplicacions d’inici de sessió

# review: new
win-built-in = (integrada)
# review: new
win-edit = &Edita...

## Opcions

# review: new
win-folders-hide = Amaga la llista de carpetes
# review: new
win-folders-pin = Mantén la llista de carpetes al costat dels missatges
# review: new
win-folders-show = Mostra les carpetes

## L’instal·lador

# les paraules pròpies de l’instal·lador (installer/inbox-classic.nsi), que la compilació converteix en
# installer/languages.nsh; { $version } i { $installed } són números de versió, 0.18.0
# review: new
win-installer-start = Inicia Inbox Classic
# review: new
win-installer-welcome-new =
    Això instal·larà Inbox Classic { $version }, un programa de correu electrònic.

    No calen permisos d’administrador: s’instal·la només per al vostre compte.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } ja està instal·lat. Això el tornarà a instal·lar.

    Es conserven els vostres comptes i el vostre correu.
# review: new
win-installer-welcome-update =
    Això actualitzarà Inbox Classic { $installed } a la versió { $version }.

    Si s’està executant, primer es tanca. Es conserven els vostres comptes i el vostre correu.
# review: new
win-installer-older-ask = Hi ha instal·lat Inbox Classic { $installed }, que és més recent que la versió { $version }. Voleu instal·lar igualment la versió anterior?
# review: new
win-installer-still-running = Inbox Classic encara s’està executant. Tanqueu-lo i torneu-ho a provar.
# review: new
win-installer-remove-mail-ask = Voleu eliminar també els comptes i el correu que Inbox Classic guarda en aquest ordinador? El correu dels servidors es conserva.
