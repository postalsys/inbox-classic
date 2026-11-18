# Les paraules de les finestres pròpies de l’aplicació de Windows (app/src), identificadors que comencen per win-. Els
# marcadors entre { $claus } els omple l’aplicació; un & marca la lletra d’un menú o d’un botó (&& és un signe &).

## La finestra principal

win-still-running-detail = Inbox Classic continua comprovant si hi ha correu nou en segon pla. Feu clic a la icona per obrir-lo. Per sortir, feu clic amb el botó dret a la icona i feu servir el seu menú.
win-default-app-not-installed = Aquesta còpia d’Inbox Classic no s’ha instal·lat, per això Windows no la mostra com a aplicació de correu. Instal·leu-la per poder-la triar.
win-default-app-settings = Windows obrirà la configuració d’Aplicacions predeterminades. Trieu Inbox Classic per obrir els enllaços MAILTO.
win-no-unread = Cap missatge sense llegir
win-unread-messages = { $count ->
    [one] 1 missatge sense llegir
   *[other] { $count } missatges sense llegir
}
win-print-failed = No s’ha pogut imprimir el missatge.
win-print-title-of = Imprimeix: { $subject }
win-no-bodies = No es pot mostrar el contingut dels missatges.
win-webview-failed = No s’ha pogut inicialitzar el WebView2.
win-webview-missing = L’entorn d’execució WebView2 no està disponible.
win-list-loading = S’està carregant...

## Botons i paraules de moltes finestres

win-delete-button = Suprimei&x
win-find-label = Ce&rca:
win-save-as-button = De&sa com a...
win-too-many-files = Heu seleccionat massa fitxers. Trieu-ne menys i torneu-ho a provar.

## La Safata de sortida


## La finestra de redacció

win-editor-failed = No es poden escriure missatges.
win-ctrl-click-to-open = ({ $ctrl }+clic per obrir)
win-format-bold = Negreta ({ $ctrl }+B)
win-format-italic = Cursiva ({ $ctrl }+I)
win-format-underline = Subratllat ({ $ctrl }+U)
win-format-link = Hiperenllaç ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = Cc&o
win-signature-title = Signatura: { $account }

## Les carpetes, la llista de missatges i la subfinestra de lectura

win-search-found-all = { $count ->
    [0] Cap resultat per a «{ $words }» a totes les carpetes
    [one] { $count } resultat per a «{ $words }» a totes les carpetes
   *[other] { $count } resultats per a «{ $words }» a totes les carpetes
}
win-search-found-in = { $count ->
    [0] Cap resultat per a «{ $words }» a la carpeta { $folder }
    [one] { $count } resultat per a «{ $words }» a la carpeta { $folder }
   *[other] { $count } resultats per a «{ $words }» a la carpeta { $folder }
}
win-search-indexing = { $count ->
    [one] encara s’està indexant el text d’un missatge
   *[other] encara s’està indexant el text de { $count } missatges
}
win-no-match-indexing = { $count ->
    [one] Encara s’està indexant el text d’un missatge, per això aviat poden aparèixer més resultats.
   *[other] Encara s’està indexant el text de { $count } missatges, per això aviat poden aparèixer més resultats.
}
win-files = { $count ->
    [one] { $count } fitxer
   *[other] { $count } fitxers
}
win-click-to-retry = Feu clic aquí per tornar-ho a provar.
win-save-attachments = De&sa els fitxers adjunts...
win-files-not-saved = Fitxers no desats: { $failed } de { $count }.
win-new-folder-in-highlighted = La carpeta nova es crearà dins de la carpeta seleccionada.
win-delete-folder-ask = Voleu suprimir la carpeta «{ $folder }» amb tots els missatges i subcarpetes que conté? També se suprimirà del servidor.
win-rename = Canvia el &nom...
win-messages-not-saved = No s’han pogut desar els missatges.
win-messages-not-forwarded = No s’han pogut reenviar els missatges.

## Comptes

win-sign-in-google = Inicia la sessió amb Google
win-sign-in-microsoft = Inicia la sessió amb Microsoft
win-next = &Següent >
win-your-account = el vostre compte
win-browser-sign-in = (inici de sessió al navegador)
win-add = &Afegeix...
win-properties-button = &Propietats...
win-signature-button = Si&gnatura...
win-sign-in-apps-button = Aplicacions d’&inici de sessió...

## Agents d’IA

win-dont-allow = &No ho permetis
win-col-address = Adreça
win-never-written-to = Cap missatge enviat
win-book-find-label = Escriviu un nom o una adreça electrònica:
win-send = &Envia
win-dont-send = &No l’enviïs
win-unsubscribe = &Cancel·la la subscripció
win-dont-unsubscribe = &No cancel·lis la subscripció
win-forget-program-ask = Voleu eliminar aquest programa, els seus permisos i l’historial d’activitat dels seus agents? Se us tornarà a demanar permís la propera vegada que es connecti.
win-clear-log-ask = Voleu esborrar l’historial d’activitat dels agents? Això no desfarà els canvis que han fet els agents.
win-agent-programs = Pro&grames que han demanat accés al vostre correu mitjançant agents:
win-change = &Canvia...
win-what-agents-did = &Activitat dels agents:
# review: new
win-agent-reads = Què s’ha llegit de { $from } a { $to }:
# review: new
win-agent-reads-hint = Seleccioneu a dalt una fila de lectures per veure què s’ha llegit.
win-how-to-connect = Com connectar un agent

## Aplicacions d’inici de sessió

win-built-in = (integrada)
win-edit = &Edita...

## Opcions

win-folders-hide = Amaga la llista de carpetes
win-folders-pin = Mantén la llista de carpetes al costat dels missatges
win-folders-show = Mostra les carpetes

## L’instal·lador

# les paraules pròpies de l’instal·lador (installer/inbox-classic.nsi), que la compilació converteix en
# installer/languages.nsh; { $version } i { $installed } són números de versió, 0.18.0
win-installer-start = Inicia Inbox Classic
win-installer-welcome-new =
    Aquest assistent instal·larà Inbox Classic { $version }, un programa de correu electrònic.

    No calen permisos d’administrador: la instal·lació només afecta el vostre compte d’usuari del Windows.
win-installer-welcome-same =
    Inbox Classic { $version } ja està instal·lat. Aquest assistent el tornarà a instal·lar.

    Es conservaran els vostres comptes i el vostre correu.
win-installer-welcome-update =
    Aquest assistent actualitzarà Inbox Classic { $installed } a la versió { $version }.

    Si s’està executant, primer es tancarà. Es conservaran els vostres comptes i el vostre correu.
win-installer-older-ask = Hi ha instal·lat Inbox Classic { $installed }, que és més recent que la versió { $version }. Voleu instal·lar igualment la versió anterior?
win-installer-still-running = Inbox Classic encara s’està executant. Tanqueu-lo i torneu-ho a provar.
win-installer-remove-mail-ask = Voleu eliminar també els comptes i el correu que Inbox Classic guarda en aquest ordinador? El correu dels servidors es conserva.
