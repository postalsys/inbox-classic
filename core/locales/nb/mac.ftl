# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Norwegian:
# an ellipsis (…) after a command that asks for more, sentence case as Apple's Norwegian menus, «» quotes.

## The app and its menus

mac-quit = Avslutt Inbox Classic
mac-settings = Innstillinger…
mac-services = Tjenester
mac-hide = Skjul Inbox Classic
mac-hide-others = Skjul andre
mac-show-all = Vis alle
mac-check-updates = Se etter oppdateringer…
mac-close-window = Lukk vindu
mac-redo = Gjør om
mac-cut = Klipp ut
mac-paste = Lim inn
mac-menu-window = Vindu
mac-minimize = Minimer
mac-zoom = Zoom
mac-no-updates = Denne versjonen av Inbox Classic støtter ikke automatiske oppdateringer. Last ned den nyeste versjonen fra inboxclassic.com.

## Settings

mac-settings-title = Innstillinger
# review: new
mac-check-updates-automatically = Se etter oppdateringer automatisk
# review: new
mac-settings-updates = Oppdateringer

## Dialogs

mac-choose = Velg

## The main window

mac-still-running-detail = Inbox Classic fortsetter å se etter ny e-post i bakgrunnen. Klikk på symbolet i Dock for å åpne appen.
mac-outbox-waiting =
    { $count ->
        [one] { $count } melding i Utboks
       *[other] { $count } meldinger i Utboks
    }
mac-sending = Sender { $subject }…
mac-checking = Ser etter nye meldinger på { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Denne kopien av Inbox Classic er ikke pakket som en macOS-app og kan derfor ikke velges som standard e-postapp.
mac-not-made-default = Kunne ikke angi Inbox Classic som standard e-postapp: { $reason }
mac-tool-search = Søk

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Teksten i { $count } melding indekseres fortsatt, så flere treff kan dukke opp snart.
       *[other] Teksten i { $count } meldinger indekseres fortsatt, så flere treff kan dukke opp snart.
    }
mac-results-everywhere =
    { $count ->
        [0] Ingen treff for «{ $words }» i alle mapper
        [one] { $count } treff for «{ $words }» i alle mapper
       *[other] { $count } treff for «{ $words }» i alle mapper
    }
mac-results-in =
    { $count ->
        [0] Ingen treff for «{ $words }» i { $folder }
        [one] { $count } treff for «{ $words }» i { $folder }
       *[other] { $count } treff for «{ $words }» i { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] indekserer fortsatt teksten i { $count } melding
       *[other] indekserer fortsatt teksten i { $count } meldinger
    }
mac-folder-unread = { $folder }; uleste: { $count }
mac-import-messages = Importer meldinger
mac-save-messages = Lagre meldinger
mac-save-attachments-menu = Lagre vedlegg…
mac-files-not-saved =
    { $count ->
       *[other] Kunne ikke lagre { $failed } av totalt { $count } filer.
    }
mac-no-calendar-app = Ingen kalenderapp på denne Macen kan åpne invitasjoner (.ics-filer).
mac-file-not-saved = Filen kunne ikke lagres.
mac-unsubscribing = Sender avmelding til { $target }…
mac-loading-list = Laster inn…

## The compose window

mac-bold = Fet
mac-italic = Kursiv
mac-underline = Understreking
mac-bcc = Blindkopi
mac-command-click-to-open = ⌘-klikk for å åpne
mac-saving-to-drafts = Lagrer i Utkast…
mac-dont-save = Ikke lagre

## The reading pane

mac-files =
    { $count ->
        [one] { $count } fil
       *[other] { $count } filer
    }

## Accounts

mac-next = Neste
mac-name-placeholder = Kari Nordmann
mac-more-sign-in-options = Flere påloggingsvalg…
mac-add-sign-in-app = Legg til en påloggingsapp…
mac-looking-up = Slår opp innstillingene for { $domain }…
mac-add-button = Legg til…
mac-properties-button = Egenskaper…
mac-signature-button = Signatur…
mac-security-button = Sikkerhet…
mac-sign-in-apps-button = Påloggingsapper…

## AI agents

mac-forget-program = Vil du fjerne dette programmet og aktivitetsloggen til agentene?
mac-forget-program-detail = Tillatelsene til programmet slettes. Du blir spurt om tillatelse igjen neste gang det kobler til.

## Sign-in apps

mac-checking-issuer = Kontrollerer { $issuer }…
mac-edit-button = Rediger…
mac-use-for-new-accounts = Bruk { $name } for nye kontoer
mac-built-in = { $name } (innebygd)

## Other windows

mac-new-folder-button = Ny mappe…
mac-edit-link = Rediger lenke…
