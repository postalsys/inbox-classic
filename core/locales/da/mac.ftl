# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Danish: an
# ellipsis (…) after a command that asks for more, only the first word capitalized, as Apple's Danish menus do.

## The app and its menus

mac-quit = Afslut Inbox Classic
mac-settings = Indstillinger…
mac-services = Tjenester
mac-hide = Skjul Inbox Classic
mac-hide-others = Skjul andre
mac-show-all = Vis alle
mac-check-updates = Søg efter opdateringer…
mac-close-window = Luk vindue
mac-redo = Gentag
mac-cut = Klip
mac-paste = Sæt ind
mac-menu-window = Vindue
mac-minimize = Minimer
mac-zoom = Zoom
mac-no-updates = Denne version af Inbox Classic understøtter ikke automatiske opdateringer. Hent den nyeste version fra inboxclassic.com.

## Settings

mac-settings-title = Indstillinger
mac-check-updates-automatically = Søg automatisk efter opdateringer
mac-settings-updates = Opdateringer

## Dialogs

mac-choose = Vælg

## The main window

mac-still-running-detail = Inbox Classic bliver ved med at søge efter ny mail i baggrunden. Klik på programmets symbol i Dock for at åbne det.
mac-outbox-waiting =
    { $count ->
        [one] { $count } meddelelse i Udbakke
       *[other] { $count } meddelelser i Udbakke
    }
mac-sending = Sender { $subject }…
mac-checking = Søger efter nye meddelelser på { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Denne kopi af Inbox Classic er ikke en programpakke, så den kan ikke være standardmailprogram.
mac-not-made-default = Inbox Classic kunne ikke indstilles som standardmailprogram: { $reason }
mac-tool-search = Søg

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Teksten i { $count } meddelelse indekseres stadig. Der kan derfor snart dukke flere resultater op.
       *[other] Teksten i { $count } meddelelser indekseres stadig. Der kan derfor snart dukke flere resultater op.
    }
mac-results-everywhere =
    { $count ->
        [0] Ingen resultater for »{ $words }« i alle mapper
        [one] { $count } resultat for »{ $words }« i alle mapper
       *[other] { $count } resultater for »{ $words }« i alle mapper
    }
mac-results-in =
    { $count ->
        [0] Ingen resultater for »{ $words }« i { $folder }
        [one] { $count } resultat for »{ $words }« i { $folder }
       *[other] { $count } resultater for »{ $words }« i { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] indekserer stadig teksten i { $count } meddelelse
       *[other] indekserer stadig teksten i { $count } meddelelser
    }
mac-folder-unread = { $folder }, { $count ->
    [one] 1 ulæst
   *[other] { $count } ulæste
}
mac-import-messages = Importer meddelelser
mac-save-messages = Gem meddelelser
mac-save-attachments-menu = Gem vedhæftede filer…
mac-files-not-saved =
    { $count ->
        [one] Filen kunne ikke gemmes.
       *[other] { $failed } af de { $count } filer kunne ikke gemmes.
    }
mac-no-calendar-app = Der er intet kalenderprogram på denne Mac, som kan åbne invitationer (.ics-filer).
mac-file-not-saved = Filen kunne ikke gemmes.
mac-unsubscribing = Sender anmodning om afmelding til { $target }…
mac-loading-list = Indlæser…

## The compose window

mac-bold = Fed
mac-italic = Kursiv
mac-underline = Understreget
mac-bcc = Bcc
mac-command-click-to-open = ⌘-klik for at åbne
mac-saving-to-drafts = Gemmer i Kladder…
mac-dont-save = Gem ikke

## The reading pane

mac-files =
    { $count ->
        [one] { $count } fil
       *[other] { $count } filer
    }

## Accounts

mac-next = Næste
mac-name-placeholder = Anne Hansen
mac-more-sign-in-options = Flere loginmuligheder…
mac-add-sign-in-app = Tilføj en login-app…
mac-looking-up = Slår indstillingerne for { $domain } op…
mac-add-button = Tilføj…
mac-properties-button = Egenskaber…
mac-signature-button = Signatur…
mac-security-button = Sikkerhed…
mac-sign-in-apps-button = Login-apps…

## AI agents

mac-forget-program = Vil du fjerne dette program og dets agenters aktivitetshistorik?
mac-forget-program-detail = Programmets tilladelser slettes. Du bliver spurgt om tilladelse igen, næste gang det opretter forbindelse.

## Sign-in apps

mac-checking-issuer = Kontrollerer { $issuer }…
mac-edit-button = Rediger…
mac-use-for-new-accounts = Brug { $name } til nye konti
mac-built-in = { $name } (indbygget)

## Other windows

mac-new-folder-button = Ny mappe…
mac-edit-link = Rediger link…
