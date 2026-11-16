# Les paraules de les finestres pròpies de l’aplicació de Linux (linux/src), identificadors que comencen per gtk-. Els
# marcadors entre { $claus } els omple l’aplicació; un _ marca la lletra mnemotècnica d’un botó. Paraules del GNOME on
# el GNOME en té (Preferències, Surt).

## La finestra principal

gtk-search-looks-in = La cerca a { $place } inclou l’assumpte, el remitent, els destinataris, el nom dels fitxers adjunts i el text dels missatges. Comproveu l’ortografia o proveu amb menys paraules.
gtk-search-still-indexing = { $count ->
    [one] Encara s’està indexant el text d’un missatge. Aviat poden aparèixer més resultats.
   *[other] Encara s’està indexant el text de { $count } missatges. Aviat poden aparèixer més resultats.
}
gtk-search-results-everywhere = { $count ->
    [0] Cap resultat
    [one] 1 resultat
   *[other] { $count } resultats
} per a «{ $words }» a totes les carpetes
gtk-search-results-in = { $count ->
    [0] Cap resultat
    [one] 1 resultat
   *[other] { $count } resultats
} per a «{ $words }» a { $place }
gtk-search-indexing = { $count ->
    [one] encara s’està indexant el text d’un missatge
   *[other] encara s’està indexant el text de { $count } missatges
}
gtk-menu-rename = Canvia el nom...
gtk-import-one-question = Voleu importar el missatge { $file } a la carpeta { $folder }?
gtk-files-not-saved = Fitxers no desats: { $failed } de { $total }.
gtk-unsubscribe-one-click =
    Voleu deixar aquesta llista de correu?

    Inbox Classic enviarà una sol·licitud de baixa a { $target }. No s’obrirà cap pàgina web ni s’enviarà cap correu electrònic.
gtk-unsubscribe-mail =
    Voleu deixar aquesta llista de correu?

    Per donar-vos de baixa, envieu un correu electrònic a { $target }. Inbox Classic us el prepararà. Envieu el missatge per confirmar-ho.
gtk-unsubscribe-web =
    Voleu deixar aquesta llista de correu?

    La pàgina de baixa de la llista de correu s’obrirà al navegador ({ $target }).
gtk-unsubscribe-failed = No s’ha pogut cancel·lar la subscripció: { $problem }
gtk-toolbar-create-mail-menu = Redacta des d’un compte concret
gtk-toolbar-send-recv-menu = Envia i rep el correu d’un compte concret
gtk-main-menu = Menú principal
gtk-folder-list = Llista de carpetes
gtk-quit = Surt

## La finestra Mou i Copia

gtk-new-folder-at-top-of = La carpeta nova es crearà al nivell superior del compte { $account }.

## La llista de missatges

## Ajuda

## Notificacions i la safata del sistema

gtk-unread-messages = { $count ->
    [0] Cap missatge sense llegir
    [one] 1 missatge sense llegir
   *[other] { $count } missatges sense llegir
}

## El menú d’enllaços de la finestra de redacció

## La Safata de sortida

gtk-outbox-empty = No hi ha cap missatge esperant per ser enviat.
gtk-outbox-row = Per a: { $to }  ·  A la cua des de { $queued }  ·  { $status }

## L’aplicació

gtk-still-running-detail = Inbox Classic continua comprovant si hi ha correu nou en segon pla. Feu servir la seva icona de la barra superior per obrir l’aplicació o sortir-ne.
gtk-sign-in-again-ask =
    S’ha rebutjat l’inici de sessió al compte { $account } o la sessió ha caducat.

    Voleu tornar a iniciar la sessió al navegador?
gtk-default-app-not-installed = Aquesta còpia d’Inbox Classic no s’ha instal·lat, per això el sistema no la mostra com a aplicació de correu. Instal·leu-la per poder-la triar.
gtk-default-app-now = Ara Inbox Classic és la vostra aplicació de correu predeterminada: els enllaços de correu electrònic obren aquí un missatge nou.
gtk-default-app-failed = No s’ha pogut definir Inbox Classic com a aplicació de correu predeterminada.

## Botons i paraules de moltes finestres

## La subfinestra de lectura

gtk-reader-date = Data:
gtk-reader-files = Fitxers adjunts del missatge
gtk-files = { $count ->
    [one] { $count } fitxer
   *[other] { $count } fitxers
}
gtk-pictures-blocked = S’han bloquejat algunes imatges per ajudar a impedir que el remitent identifiqui el vostre ordinador.
gtk-download-pictures = Baixa les imatges
gtk-save-attachments-menu = Desa els fitxers adjunts...

## La finestra de redacció

gtk-format-bold = Negreta (Ctrl+B)
gtk-format-italic = Cursiva (Ctrl+I)
gtk-format-underline = Subratllat (Ctrl+U)
gtk-format-hyperlink = Hiperenllaç (Ctrl+K)
gtk-font = Tipus de lletra
gtk-show-cc = _Cc
gtk-show-bcc = Cc_o
gtk-save-tip = Desa (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clic per obrir)

## Comptes

gtk-plain-warning =
    Sense xifratge, qualsevol persona que intercepti el trànsit de la xarxa pot llegir la vostra contrasenya i els vostres missatges. Feu servir aquesta connexió només amb un servidor del vostre ordinador o de la vostra xarxa local.

    Voleu continuar?
gtk-account-name-title = Nom del compte
gtk-display-name-title = Nom visible
gtk-turned-off-why = L’opció «{ $button }» està desactivada en aquest ordinador. { $reason }
gtk-turned-off-why-long =
    L’opció «{ $button }» està desactivada en aquest ordinador.

    { $reason }
gtk-next = Següent >
gtk-provider-sign-in = { $provider }: inicieu la sessió al compte { $address } al lloc web del proveïdor. La vostra contrasenya no es comparteix amb Inbox Classic. També podeu fer servir una contrasenya d’aplicació creada a la configuració de seguretat del compte.
gtk-provider-sign-in-apps = { $provider }: inicieu la sessió al compte { $address } al lloc web del proveïdor amb una de les vostres aplicacions d’inici de sessió (Més opcions d’inici de sessió). També podeu fer servir una contrasenya d’aplicació creada a la configuració de seguretat del compte.
gtk-accounts-add = Afegeix...
gtk-accounts-properties = Propietats...
gtk-accounts-signature = Signatura...
gtk-accounts-sign-in-apps = Aplicacions d’inici de sessió...

## Aplicacions d’inici de sessió

gtk-app-server = Servidor { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Seguretat { $kind }
gtk-issuer-found =
    Pàgina d’inici de sessió: { $page }
    Adreça d’obtenció de testimonis: { $endpoint }
gtk-client-id = Identificador de client
gtk-client-secret = Secret de client
gtk-scopes = Permisos (scopes)
gtk-redirect-uri = URI de redirecció
gtk-issuer-usable =
    Es pot fer servir l’emissor.

    { $found }
gtk-app-built-in = L’aplicació { $app } està integrada a Inbox Classic. Només podeu triar si apareix entre les opcions d’inici de sessió en afegir comptes. { $reason }
gtk-built-in = { $app } (integrada)
gtk-offered-for-new = S’ofereix per als comptes nous
gtk-edit-button = Edita...
gtk-remove-app-ask = Voleu eliminar l’aplicació d’inici de sessió { $app } i el secret de client desat?
gtk-sign-in-apps-intro = Les aplicacions d’inici de sessió permeten accedir als comptes a través del navegador. Si una aplicació està desactivada, no s’ofereix en afegir comptes. Els comptes que ja la fan servir continuen funcionant.

## Agents d’IA

gtk-agent-it-may = Accions permeses
gtk-agent-accounts = Comptes permesos
gtk-never-used = No s’ha fet servir mai
gtk-last-used = Darrer ús: { $date }
gtk-forget-program = Voleu eliminar aquest programa?
gtk-forget-program-detail = S’eliminaran els permisos del programa i l’historial d’activitat dels seus agents. Se us tornarà a demanar permís la propera vegada que es connecti.
gtk-no-agents-yet = Encara no hi ha cap agent que hagi demanat accés al vostre correu.
gtk-nothing-yet = Encara no hi ha activitat.

## Preferències

gtk-preferences = Preferències
gtk-language = Llengua
gtk-language-subtitle = Llengua de l’aplicació i de l’ajuda
gtk-new-mail-group = Correu nou
# la fila de les Preferències que activa la notificació de correu nou, amb majúscula només inicial com fa el GNOME
gtk-notify-new-mail = Notifica el correu nou
gtk-notify-subtitle = Mostra una notificació quan arriben missatges mentre la finestra és en segon pla
gtk-restart-to-change = Cal reiniciar Inbox Classic per aplicar el canvi de llengua.

## L’entrada d’escriptori i la pàgina de les botigues de programari

# linux/data/com.inboxclassic.InboxClassic.desktop i .metainfo.xml, generats per la compilació. Les paraules clau són les
# paraules amb què una cerca d’aplicacions troba Inbox Classic, cadascuna acabada amb un punt i coma, només en la vostra
# llengua: les angleses s’afegeixen davant
gtk-desktop-generic-name = Client de correu
gtk-desktop-comment = Llegiu i escriviu correu electrònic: un programa de correu ràpid i senzill
gtk-desktop-keywords = correu;correu electrònic;missatge;safata d’entrada;
gtk-metainfo-summary = Un programa de correu ràpid i senzill
gtk-metainfo-description = Inbox Classic permet llegir i escriure correu electrònic amb una disposició familiar: carpetes a l’esquerra, llista de missatges a dalt i contingut del missatge seleccionat a sota. Funciona amb qualsevol compte IMAP i SMTP i permet iniciar la sessió a Outlook.com i Microsoft 365 a través del navegador.
gtk-metainfo-feature-sanitized = Els missatges es mostren sense scripts ni altres continguts potencialment perillosos; les imatges d’internet només es carreguen amb la vostra autorització
gtk-metainfo-feature-search = Cerca a l’assumpte, els remitents, els destinataris, els noms dels fitxers adjunts i el text dels missatges, amb els operadors del Gmail
gtk-metainfo-feature-replies = El text de missatges anteriors citat a les respostes queda plegat i es pot desplegar quan calgui
gtk-metainfo-feature-offline = El correu ja baixat es pot llegir sense connexió; les contrasenyes es desen a l’anell de claus del sistema
