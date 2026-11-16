# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Danish: an
# ellipsis (…) after a command that asks for more, only the first word capitalized, as Apple's Danish menus do.

## The app and its menus

# review: new
mac-quit = Afslut Inbox Classic
# review: new
mac-settings = Indstillinger…
# review: new
mac-services = Tjenester
# review: new
mac-hide = Skjul Inbox Classic
# review: new
mac-hide-others = Skjul andre
# review: new
mac-show-all = Vis alle
# review: new
mac-check-updates = Søg efter opdateringer…
# review: new
mac-close-window = Luk vindue
# review: new
mac-redo = Gentag
# review: new
mac-cut = Klip
# review: new
mac-paste = Sæt ind
# review: new
mac-menu-window = Vindue
# review: new
mac-minimize = Minimer
# review: new
mac-zoom = Zoom
# review: new
mac-no-updates = Denne version af Inbox Classic understøtter ikke automatiske opdateringer. Hent den nyeste version fra inboxclassic.com.

## Settings

# review: new
mac-settings-title = Indstillinger
# review: new
mac-check-updates-automatically = Søg automatisk efter opdateringer

## Dialogs

# review: new
mac-choose = Vælg

## The main window

# review: new
mac-still-running-detail = Inbox Classic bliver ved med at søge efter ny mail i baggrunden. Klik på programmets symbol i Dock for at åbne det.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } meddelelse i Udbakke
       *[other] { $count } meddelelser i Udbakke
    }
# review: new
mac-sending = Sender { $subject }…
# review: new
mac-checking = Søger efter nye meddelelser på { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Denne kopi af Inbox Classic er ikke en programpakke, så den kan ikke være standardmailprogram.
# review: new
mac-not-made-default = Inbox Classic blev ikke gjort til standardmailprogram: { $reason }
# review: new
mac-tool-search = Søg

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Teksten i { $count } meddelelse indekseres stadig, så der findes måske snart flere.
       *[other] Teksten i { $count } meddelelser indekseres stadig, så der findes måske snart flere.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Ingen resultater for »{ $words }« i alle mapper
        [one] { $count } resultat for »{ $words }« i alle mapper
       *[other] { $count } resultater for »{ $words }« i alle mapper
    }
# review: new
mac-results-in =
    { $count ->
        [0] Ingen resultater for »{ $words }« i { $folder }
        [one] { $count } resultat for »{ $words }« i { $folder }
       *[other] { $count } resultater for »{ $words }« i { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] indekserer stadig teksten i { $count } meddelelse
       *[other] indekserer stadig teksten i { $count } meddelelser
    }
# review: new
mac-folder-unread = { $folder }, { $count } ulæste
# review: new
mac-import-messages = Importer meddelelser
# review: new
mac-save-messages = Gem meddelelser
# review: new
mac-save-attachments-menu = Gem vedhæftede filer…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $failed } af de { $count } filer kunne ikke gemmes.
    }
# review: new
mac-no-calendar-app = Der er intet kalenderprogram på denne Mac, som kan åbne invitationer (.ics-filer).
# review: new
mac-file-not-saved = Filen kunne ikke gemmes.
# review: new
mac-unsubscribing = Afmelder fra { $target }…
# review: new
mac-loading-list = Indlæser…

## The compose window

# review: new
mac-bold = Fed
# review: new
mac-italic = Kursiv
# review: new
mac-underline = Understreget
# review: new
mac-bcc = Bcc
# review: new
mac-command-click-to-open = ⌘-klik for at åbne
# review: new
mac-saving-to-drafts = Gemmer i Kladder…
# review: new
mac-dont-save = Gem ikke

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } fil
       *[other] { $count } filer
    }

## Accounts

# review: new
mac-next = Næste
# review: new
mac-name-placeholder = Anne Hansen
# review: new
mac-more-sign-in-options = Flere loginmuligheder…
# review: new
mac-add-sign-in-app = Tilføj en login-app…
# review: new
mac-looking-up = Slår indstillingerne for { $domain } op…
# review: new
mac-add-button = Tilføj…
# review: new
mac-properties-button = Egenskaber…
# review: new
mac-signature-button = Signatur…
# review: new
mac-security-button = Sikkerhed…
# review: new
mac-sign-in-apps-button = Login-apps…

## AI agents

# review: new
mac-forget-program = Vil du fjerne dette program og dets agenters aktivitetshistorik?
# review: new
mac-forget-program-detail = Programmets tilladelser slettes. Du bliver spurgt om tilladelse igen, næste gang det opretter forbindelse.

## Sign-in apps

# review: new
mac-checking-issuer = Kontrollerer { $issuer }…
# review: new
mac-edit-button = Rediger…
# review: new
mac-use-for-new-accounts = Brug { $name } til nye konti
# review: new
mac-built-in = { $name } (indbygget)

## Other windows

# review: new
mac-new-folder-button = Ny mappe…
# review: new
mac-edit-link = Rediger link…
