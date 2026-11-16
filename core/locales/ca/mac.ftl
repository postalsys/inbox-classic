# Les paraules de les finestres pròpies de l’aplicació del Mac (mac/Sources), identificadors que comencen per mac-; els
# menús i les paraules que comparteixen totes les plataformes són a app.ftl i core.ftl. Els marcadors entre { $claus }
# els omple l’aplicació. Convencions del Mac: punts suspensius (…) després d’una ordre que demana més dades; els menús
# del sistema en infinitiu, com fa el macOS en català; cometes « » i apòstrof ’.

## L’aplicació i els seus menús

# review: new
mac-quit = Sortir d’Inbox Classic
# review: new
mac-settings = Configuració…
# review: new
mac-services = Serveis
# review: new
mac-hide = Amagar Inbox Classic
# review: new
mac-hide-others = Amagar els altres
# review: new
mac-show-all = Mostrar-ho tot
# review: new
mac-check-updates = Buscar actualitzacions…
# review: new
mac-close-window = Tancar la finestra
# review: new
mac-redo = Refer
# review: new
mac-cut = Retallar
# review: new
mac-paste = Enganxar
# review: new
mac-menu-window = Finestra
# review: new
mac-minimize = Minimitzar
# review: new
mac-zoom = Zoom
# review: new
mac-no-updates = Aquesta versió d’Inbox Classic no admet actualitzacions automàtiques. Baixeu la versió més recent des d’inboxclassic.com.

## Configuració

# review: new
mac-settings-title = Configuració
# review: new
mac-language-label = Llengua:
# review: new
mac-restart-hint = Reinicieu Inbox Classic per canviar la llengua.
# review: new
mac-notify-new-mail = Notifica’m quan arribi correu nou
# review: new
mac-restart-question = Voleu reiniciar Inbox Classic ara per canviar la llengua?

## Diàlegs

# review: new
mac-choose = Tria

## La finestra principal

# review: new
mac-still-running-detail = Inbox Classic continua comprovant si hi ha correu nou en segon pla. Feu clic a la seva icona al Dock per obrir l’aplicació.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } missatge a la Safata de sortida
       *[other] { $count } missatges a la Safata de sortida
    }
# review: new
mac-sending = S’està enviant { $subject }…
# review: new
mac-checking = S’està comprovant si hi ha missatges nous al compte { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Aquesta còpia d’Inbox Classic no és un paquet d’aplicació, per això no pot ser l’aplicació de correu predeterminada.
# review: new
mac-not-made-default = Inbox Classic no s’ha definit com a aplicació de correu predeterminada: { $reason }
# review: new
mac-tool-search = Cerca

## Les carpetes i la llista de missatges

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Encara s’està indexant el text de { $count } missatge, per això aviat se’n poden trobar més.
       *[other] Encara s’està indexant el text de { $count } missatges, per això aviat se’n poden trobar més.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Cap resultat per a «{ $words }» a totes les carpetes
        [one] { $count } resultat per a «{ $words }» a totes les carpetes
       *[other] { $count } resultats per a «{ $words }» a totes les carpetes
    }
# review: new
mac-results-in =
    { $count ->
        [0] Cap resultat per a «{ $words }» a la carpeta { $folder }
        [one] { $count } resultat per a «{ $words }» a la carpeta { $folder }
       *[other] { $count } resultats per a «{ $words }» a la carpeta { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] encara s’està indexant el text de { $count } missatge
       *[other] encara s’està indexant el text de { $count } missatges
    }
# review: new
mac-folder-unread = { $folder }, { $count } sense llegir
# review: new
mac-import-messages = Importa missatges
# review: new
mac-save-messages = Desa els missatges
# review: new
mac-save-attachments-menu = Desa els fitxers adjunts…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] No s’han pogut desar { $failed } dels { $count } fitxers.
    }
# review: new
mac-no-calendar-app = En aquest Mac no hi ha cap aplicació de calendari per obrir invitacions (fitxers .ics).
# review: new
mac-file-not-saved = No s’ha pogut desar el fitxer.
# review: new
mac-unsubscribing = S’està cancel·lant la subscripció a { $target }…

## La finestra de redacció

# review: new
mac-bold = Negreta
# review: new
mac-italic = Cursiva
# review: new
mac-underline = Subratllat
# review: new
mac-bcc = Cco
# review: new
mac-command-click-to-open = ⌘+clic per obrir
# review: new
mac-saving-to-drafts = S’està desant a Esborranys…
# review: new
mac-dont-save = No desis

## La subfinestra de lectura

# review: new
mac-files =
    { $count ->
        [one] { $count } fitxer
       *[other] { $count } fitxers
    }

## Comptes

# review: new
mac-next = Següent
# review: new
mac-name-placeholder = Anna Puig
# review: new
mac-more-sign-in-options = Més opcions d’inici de sessió…
# review: new
mac-add-sign-in-app = Afegeix una aplicació d’inici de sessió…
# review: new
mac-looking-up = S’està cercant la configuració del domini { $domain }…
# review: new
mac-add-button = Afegeix…
# review: new
mac-properties-button = Propietats…
# review: new
mac-signature-button = Signatura…
# review: new
mac-security-button = Seguretat…
# review: new
mac-sign-in-apps-button = Aplicacions d’inici de sessió…

## Agents d’IA

# review: new
mac-forget-program = Voleu eliminar aquest programa i l’historial d’activitat dels seus agents?
# review: new
mac-forget-program-detail = S’eliminaran els permisos del programa. Se us tornarà a demanar permís la propera vegada que es connecti.

## Aplicacions d’inici de sessió

# review: new
mac-checking-issuer = S’està comprovant { $issuer }…
# review: new
mac-edit-button = Edita…
# review: new
mac-use-for-new-accounts = Usa { $name } per als comptes nous
# review: new
mac-built-in = { $name } (integrada)

## Altres finestres

# review: new
mac-new-folder-button = Carpeta nova…
# review: new
mac-edit-link = Edita l’enllaç…
