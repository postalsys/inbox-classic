# Les paraules de les finestres pròpies de l’aplicació de Linux (linux/src), identificadors que comencen per gtk-. Els
# marcadors entre { $claus } els omple l’aplicació; un _ marca la lletra mnemotècnica d’un botó. Paraules del GNOME on
# el GNOME en té (Preferències, Surt).

## La finestra principal

# review: new
gtk-search-looks-in = La cerca a { $place } inclou l’assumpte, el remitent, els destinataris, el nom dels fitxers adjunts i el text dels missatges. Comproveu l’ortografia o proveu amb menys paraules.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Encara s’està indexant el text d’1 missatge. Aviat poden aparèixer més resultats.
   *[other] Encara s’està indexant el text de { $count } missatges. Aviat poden aparèixer més resultats.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Cap resultat
    [one] 1 resultat
   *[other] { $count } resultats
} per a «{ $words }» a totes les carpetes
# review: new
gtk-search-results-in = { $count ->
    [0] Cap resultat
    [one] 1 resultat
   *[other] { $count } resultats
} per a «{ $words }» a { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] encara s’està indexant el text d’1 missatge
   *[other] encara s’està indexant el text de { $count } missatges
}
# review: new
gtk-menu-rename = Canvia el nom...
# review: new
gtk-import-one-question = Voleu importar el missatge { $file } a la carpeta { $folder }?
# review: new
gtk-files-not-saved = No s’han pogut desar { $failed } dels { $total } fitxers.
# review: new
gtk-unsubscribe-one-click =
    Voleu deixar aquesta llista de correu?

    Inbox Classic enviarà una sol·licitud de baixa a { $target }. No s’obrirà cap pàgina web ni s’enviarà cap correu electrònic.
# review: new
gtk-unsubscribe-mail =
    Voleu deixar aquesta llista de correu?

    Per donar-vos de baixa, envieu un correu electrònic a { $target }. Inbox Classic us el prepararà. Envieu el missatge per confirmar-ho.
# review: new
gtk-unsubscribe-web =
    Voleu deixar aquesta llista de correu?

    La pàgina de baixa de la llista de correu s’obrirà al navegador ({ $target }).
# review: new
gtk-unsubscribe-failed = No s’ha pogut cancel·lar la subscripció: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Redacta des d’un compte concret
# review: new
gtk-toolbar-send-recv-menu = Envia i rep el correu d’un compte concret
# review: new
gtk-main-menu = Menú principal
# review: new
gtk-folder-list = Llista de carpetes
# review: new
gtk-quit = Surt

## La finestra Mou i Copia

# review: new
gtk-new-folder-at-top-of = La carpeta nova es crea al nivell superior del compte { $account }.

## La llista de missatges

## Ajuda

## Notificacions i la safata del sistema

# review: new
gtk-unread-messages = { $count ->
    [0] Cap missatge sense llegir
    [one] 1 missatge sense llegir
   *[other] { $count } missatges sense llegir
}

## El menú d’enllaços de la finestra de redacció

## La Safata de sortida

# review: new
gtk-outbox-empty = No hi ha cap missatge esperant per ser enviat.
# review: new
gtk-outbox-row = Per a: { $to }  ·  A la cua: { $queued }  ·  { $status }

## L’aplicació

# review: new
gtk-still-running-detail = Inbox Classic continua comprovant si hi ha correu nou en segon pla. Feu servir la seva icona de la barra superior per obrir l’aplicació o sortir-ne.
# review: new
gtk-sign-in-again-ask =
    S’ha rebutjat l’inici de sessió al compte { $account } o la sessió ha caducat.

    Voleu tornar a iniciar la sessió al navegador?
# review: new
gtk-default-app-not-installed = Aquesta còpia d’Inbox Classic no s’ha instal·lat, per això el sistema no la mostra com a aplicació de correu. Instal·leu-la per poder-la triar.
# review: new
gtk-default-app-now = Ara Inbox Classic és la vostra aplicació de correu predeterminada: els enllaços de correu electrònic obren aquí un missatge nou.
# review: new
gtk-default-app-failed = No s’ha pogut definir Inbox Classic com a aplicació de correu predeterminada.

## Botons i paraules de moltes finestres

## La subfinestra de lectura

# review: new
gtk-reader-date = Data:
# review: new
gtk-reader-files = Fitxers adjunts del missatge
# review: new
gtk-files = { $count ->
    [one] { $count } fitxer
   *[other] { $count } fitxers
}
# review: new
gtk-pictures-blocked = S’han bloquejat algunes imatges perquè el remitent no pugui identificar el vostre ordinador.
# review: new
gtk-download-pictures = Baixa les imatges
# review: new
gtk-save-attachments-menu = Desa els fitxers adjunts...

## La finestra de redacció

# review: new
gtk-format-bold = Negreta (Ctrl+B)
# review: new
gtk-format-italic = Cursiva (Ctrl+I)
# review: new
gtk-format-underline = Subratllat (Ctrl+U)
# review: new
gtk-format-hyperlink = Hiperenllaç (Ctrl+K)
# review: new
gtk-font = Tipus de lletra
# review: new
gtk-show-cc = _Cc
gtk-show-bcc = Cc_o
# review: new
gtk-save-tip = Desa (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+clic per obrir)

## Comptes

# review: new
gtk-plain-warning =
    Sense xifratge, qualsevol persona que intercepti el trànsit de la xarxa pot llegir la vostra contrasenya i els vostres missatges. Feu servir aquesta connexió només amb un servidor del vostre ordinador o de la vostra xarxa local.

    Voleu continuar?
# review: new
gtk-account-name-title = Nom del compte
# review: new
gtk-display-name-title = Nom visible
# review: new
gtk-turned-off-why = L’opció «{ $button }» està desactivada en aquest ordinador. { $reason }
# review: new
gtk-turned-off-why-long =
    L’opció «{ $button }» està desactivada en aquest ordinador.

    { $reason }
# review: new
gtk-next = Següent >
gtk-provider-sign-in = { $provider }: inicieu la sessió al compte { $address } al lloc web del proveïdor. La vostra contrasenya no es comparteix amb Inbox Classic. També podeu fer servir una contrasenya d’aplicació creada a la configuració de seguretat del compte.
gtk-provider-sign-in-apps = { $provider }: inicieu la sessió al compte { $address } al lloc web del proveïdor amb una de les vostres aplicacions d’inici de sessió (Més opcions d’inici de sessió). També podeu fer servir una contrasenya d’aplicació creada a la configuració de seguretat del compte.
# review: new
gtk-accounts-add = Afegeix...
# review: new
gtk-accounts-properties = Propietats...
# review: new
gtk-accounts-signature = Signatura...
# review: new
gtk-accounts-sign-in-apps = Aplicacions d’inici de sessió...

## Aplicacions d’inici de sessió

# review: new
gtk-app-server = Servidor { $kind }
# review: new
gtk-app-port = Port { $kind }
# review: new
gtk-app-security = Seguretat { $kind }
# review: new
gtk-issuer-found =
    Pàgina d’inici de sessió: { $page }
    Punt final del testimoni: { $endpoint }
# review: new
gtk-client-id = Identificador de client
# review: new
gtk-client-secret = Secret de client
# review: new
gtk-scopes = Permisos (scopes)
# review: new
gtk-redirect-uri = URI de redirecció
# review: new
gtk-issuer-usable =
    Es pot fer servir l’emissor.

    { $found }
# review: new
gtk-app-built-in = { $app } és integrada. Només podeu canviar si s’ofereix per als comptes nous. { $reason }
# review: new
gtk-built-in = { $app } (integrada)
# review: new
gtk-offered-for-new = S’ofereix per als comptes nous
# review: new
gtk-edit-button = Edita...
# review: new
gtk-remove-app-ask = Voleu eliminar l’aplicació d’inici de sessió { $app } i el secret de client desat?
# review: new
gtk-sign-in-apps-intro = Les aplicacions d’inici de sessió permeten que els comptes iniciïn la sessió a través del navegador. Una que estigui desactivada no s’ofereix per als comptes nous; els comptes que ja la fan servir continuen funcionant.

## Agents d’IA

# review: new
gtk-agent-it-may = Accions permeses
# review: new
gtk-agent-accounts = Comptes permesos
# review: new
gtk-never-used = No s’ha fet servir mai
# review: new
gtk-last-used = Darrer ús: { $date }
# review: new
gtk-forget-program = Voleu eliminar aquest programa?
# review: new
gtk-forget-program-detail = S’eliminaran els permisos del programa i l’historial d’activitat dels seus agents. Se us tornarà a demanar permís la propera vegada que es connecti.
# review: new
gtk-no-agents-yet = Encara cap agent no ha demanat fer servir el vostre correu.
# review: new
gtk-nothing-yet = Encara res.

## Preferències

# review: new
gtk-preferences = Preferències
# review: new
gtk-language = Llengua
# review: new
gtk-language-subtitle = Llengua de l’aplicació i de l’ajuda
# review: new
gtk-new-mail-group = Correu nou
# la fila de les Preferències que activa la notificació de correu nou, amb majúscula només inicial com fa el GNOME
# review: new
gtk-notify-new-mail = Notifica el correu nou
# review: new
gtk-notify-subtitle = Una notificació quan arriben missatges nous mentre la finestra és en segon pla
# review: new
gtk-restart-to-change = Inbox Classic es reinicia per canviar la llengua.

## L’entrada d’escriptori i la pàgina de les botigues de programari

# linux/data/com.inboxclassic.InboxClassic.desktop i .metainfo.xml, generats per la compilació. Les paraules clau són les
# paraules amb què una cerca d’aplicacions troba Inbox Classic, cadascuna acabada amb un punt i coma, només en la vostra
# llengua: les angleses s’afegeixen davant
# review: new
gtk-desktop-generic-name = Client de correu
# review: new
gtk-desktop-comment = Llegiu i escriviu correu electrònic: un programa de correu ràpid i senzill
# review: new
gtk-desktop-keywords = correu;correu electrònic;missatge;safata d’entrada;
# review: new
gtk-metainfo-summary = Un programa de correu ràpid i senzill
# review: new
gtk-metainfo-description = Inbox Classic llegeix i escriu correu electrònic amb les carpetes a l’esquerra, els missatges a dalt i el missatge a sota, com feien els programes de correu d’abans. Funciona amb qualsevol compte IMAP i SMTP, i inicia la sessió a Outlook.com i Microsoft 365 a través del navegador.
# review: new
gtk-metainfo-feature-sanitized = Cada missatge es mostra netejat, sense scripts, i les imatges d’Internet només quan les permeteu
# review: new
gtk-metainfo-feature-search = Una cerca que troba paraules a l’assumpte, les persones, els noms de fitxer i el text, amb els operadors del Gmail
# review: new
gtk-metainfo-feature-replies = Les respostes plegen els missatges anteriors que citen
# review: new
gtk-metainfo-feature-offline = El correu es pot llegir sense connexió; les contrasenyes es guarden al vostre anell de claus
