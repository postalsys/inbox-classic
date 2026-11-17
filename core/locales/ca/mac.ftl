# Les paraules de les finestres pròpies de l’aplicació del Mac (mac/Sources), identificadors que comencen per mac-; els
# menús i les paraules que comparteixen totes les plataformes són a app.ftl i core.ftl. Els marcadors entre { $claus }
# els omple l’aplicació. Convencions del Mac: punts suspensius (…) després d’una ordre que demana més dades; els menús
# del sistema en infinitiu, com fa el macOS en català; cometes « » i apòstrof ’.

## L’aplicació i els seus menús

mac-quit = Sortir d’Inbox Classic
mac-settings = Configuració…
mac-services = Serveis
mac-hide = Amagar Inbox Classic
mac-hide-others = Amagar els altres
mac-show-all = Mostrar-ho tot
mac-check-updates = Buscar actualitzacions…
mac-close-window = Tancar la finestra
mac-redo = Refer
mac-cut = Retallar
mac-paste = Enganxar
mac-menu-window = Finestra
mac-minimize = Minimitzar
mac-zoom = Zoom
mac-no-updates = Aquesta versió d’Inbox Classic no admet actualitzacions automàtiques. Baixeu la versió més recent des d’inboxclassic.com.

## Configuració

mac-settings-title = Configuració
mac-check-updates-automatically = Buscar actualitzacions automàticament
mac-settings-updates = Actualitzacions

## Diàlegs

mac-choose = Tria

## La finestra principal

mac-still-running-detail = Inbox Classic continua comprovant si hi ha correu nou en segon pla. Feu clic a la seva icona al Dock per obrir l’aplicació.
mac-outbox-waiting =
    { $count ->
        [one] { $count } missatge a la Safata de sortida
       *[other] { $count } missatges a la Safata de sortida
    }
mac-sending = S’està enviant { $subject }…
mac-checking = S’està comprovant si hi ha missatges nous al compte { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Aquesta còpia d’Inbox Classic no és dins d’un paquet .app del macOS i no es pot definir com a aplicació de correu predeterminada.
mac-not-made-default = Inbox Classic no s’ha definit com a aplicació de correu predeterminada: { $reason }
mac-tool-search = Cerca

## Les carpetes i la llista de missatges

mac-still-indexing-more =
    { $count ->
        [one] Encara s’està indexant el text d’un missatge, per això aviat poden aparèixer més resultats.
       *[other] Encara s’està indexant el text de { $count } missatges, per això aviat poden aparèixer més resultats.
    }
mac-results-everywhere =
    { $count ->
        [0] Cap resultat per a «{ $words }» a totes les carpetes
        [one] { $count } resultat per a «{ $words }» a totes les carpetes
       *[other] { $count } resultats per a «{ $words }» a totes les carpetes
    }
mac-results-in =
    { $count ->
        [0] Cap resultat per a «{ $words }» a la carpeta { $folder }
        [one] { $count } resultat per a «{ $words }» a la carpeta { $folder }
       *[other] { $count } resultats per a «{ $words }» a la carpeta { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] encara s’està indexant el text d’un missatge
       *[other] encara s’està indexant el text de { $count } missatges
    }
mac-folder-unread = { $folder }, { $count } sense llegir
mac-import-messages = Importa missatges
mac-save-messages = Desa els missatges
mac-save-attachments-menu = Desa els fitxers adjunts…
mac-files-not-saved =
    { $count ->
       *[other] Fitxers no desats: { $failed } de { $count }.
    }
mac-no-calendar-app = En aquest Mac no hi ha cap aplicació de calendari per obrir invitacions (fitxers .ics).
mac-file-not-saved = No s’ha pogut desar el fitxer.
mac-unsubscribing = S’està cancel·lant la subscripció a { $target }…
mac-loading-list = S’està carregant…

## La finestra de redacció

mac-bold = Negreta
mac-italic = Cursiva
mac-underline = Subratllat
mac-bcc = Cco
mac-command-click-to-open = ⌘+clic per obrir
mac-saving-to-drafts = S’està desant a Esborranys…
mac-dont-save = No desis

## La subfinestra de lectura

mac-files =
    { $count ->
        [one] { $count } fitxer
       *[other] { $count } fitxers
    }

## Comptes

mac-next = Següent
mac-name-placeholder = Anna Puig
mac-more-sign-in-options = Més opcions d’inici de sessió…
mac-add-sign-in-app = Afegeix una aplicació d’inici de sessió…
mac-looking-up = S’està cercant la configuració del domini { $domain }…
mac-add-button = Afegeix…
mac-properties-button = Propietats…
mac-signature-button = Signatura…
mac-security-button = Seguretat…
mac-sign-in-apps-button = Aplicacions d’inici de sessió…

## Agents d’IA

mac-forget-program = Voleu eliminar aquest programa i l’historial d’activitat dels seus agents?
mac-forget-program-detail = S’eliminaran els permisos del programa. Se us tornarà a demanar permís la propera vegada que es connecti.

## Aplicacions d’inici de sessió

mac-checking-issuer = S’està comprovant { $issuer }…
mac-edit-button = Edita…
mac-use-for-new-accounts = Usa { $name } per als comptes nous
mac-built-in = { $name } (integrada)

## Altres finestres

mac-new-folder-button = Carpeta nova…
mac-edit-link = Edita l’enllaç…
