# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Norwegian:
# an ellipsis (…) after a command that asks for more, sentence case as Apple's Norwegian menus, «» quotes.

## The app and its menus

# review: new
mac-quit = Avslutt Inbox Classic
# review: new
mac-settings = Innstillinger…
# review: new
mac-services = Tjenester
# review: new
mac-hide = Skjul Inbox Classic
# review: new
mac-hide-others = Skjul andre
# review: new
mac-show-all = Vis alle
# review: new
mac-check-updates = Se etter oppdateringer…
# review: new
mac-close-window = Lukk vindu
# review: new
mac-redo = Gjør om
# review: new
mac-cut = Klipp ut
# review: new
mac-paste = Lim inn
# review: new
mac-menu-window = Vindu
# review: new
mac-minimize = Minimer
# review: new
mac-zoom = Zoom
# review: new
mac-no-updates = Denne versjonen av Inbox Classic støtter ikke automatiske oppdateringer. Last ned den nyeste versjonen fra inboxclassic.com.

## Settings

# review: new
mac-settings-title = Innstillinger
# review: new
mac-check-updates-automatically = Se etter oppdateringer automatisk

## Dialogs

# review: new
mac-choose = Velg

## The main window

# review: new
mac-still-running-detail = Inbox Classic fortsetter å se etter ny e-post i bakgrunnen. Klikk på symbolet i Dock for å åpne appen.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } melding i Utboks
       *[other] { $count } meldinger i Utboks
    }
# review: new
mac-sending = Sender { $subject }…
# review: new
mac-checking = Ser etter nye meldinger på { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Denne kopien av Inbox Classic er ikke en apppakke, så den kan ikke være standard e-postapp.
# review: new
mac-not-made-default = Inbox Classic ble ikke gjort til standard e-postapp: { $reason }
# review: new
mac-tool-search = Søk

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Teksten i { $count } melding indekseres fortsatt, så flere treff kan dukke opp snart.
       *[other] Teksten i { $count } meldinger indekseres fortsatt, så flere treff kan dukke opp snart.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Ingen treff for «{ $words }» i alle mapper
        [one] { $count } treff for «{ $words }» i alle mapper
       *[other] { $count } treff for «{ $words }» i alle mapper
    }
# review: new
mac-results-in =
    { $count ->
        [0] Ingen treff for «{ $words }» i { $folder }
        [one] { $count } treff for «{ $words }» i { $folder }
       *[other] { $count } treff for «{ $words }» i { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] indekserer fortsatt teksten i { $count } melding
       *[other] indekserer fortsatt teksten i { $count } meldinger
    }
# review: new
mac-folder-unread = { $folder }, { $count } uleste
# review: new
mac-import-messages = Importer meldinger
# review: new
mac-save-messages = Lagre meldinger
# review: new
mac-save-attachments-menu = Lagre vedlegg…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $failed } av de { $count } filene kunne ikke lagres.
    }
# review: new
mac-no-calendar-app = Ingen kalenderapp på denne Macen kan åpne invitasjoner (.ics-filer).
# review: new
mac-file-not-saved = Filen kunne ikke lagres.
# review: new
mac-unsubscribing = Melder av { $target }…
# review: new
mac-loading-list = Laster inn…

## The compose window

# review: new
mac-bold = Fet
# review: new
mac-italic = Kursiv
# review: new
mac-underline = Understreking
# review: new
mac-bcc = Blindkopi
# review: new
mac-command-click-to-open = ⌘-klikk for å åpne
# review: new
mac-saving-to-drafts = Lagrer i Utkast…
# review: new
mac-dont-save = Ikke lagre

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } fil
       *[other] { $count } filer
    }

## Accounts

# review: new
mac-next = Neste
# review: new
mac-name-placeholder = Kari Nordmann
# review: new
mac-more-sign-in-options = Flere påloggingsvalg…
# review: new
mac-add-sign-in-app = Legg til en påloggingsapp…
# review: new
mac-looking-up = Slår opp innstillingene for { $domain }…
# review: new
mac-add-button = Legg til…
# review: new
mac-properties-button = Egenskaper…
# review: new
mac-signature-button = Signatur…
# review: new
mac-security-button = Sikkerhet…
# review: new
mac-sign-in-apps-button = Påloggingsapper…

## AI agents

# review: new
mac-forget-program = Vil du fjerne dette programmet og aktivitetsloggen til agentene?
# review: new
mac-forget-program-detail = Tillatelsene til programmet slettes. Du blir spurt om tillatelse igjen neste gang det kobler til.

## Sign-in apps

# review: new
mac-checking-issuer = Kontrollerer { $issuer }…
# review: new
mac-edit-button = Rediger…
# review: new
mac-use-for-new-accounts = Bruk { $name } for nye kontoer
# review: new
mac-built-in = { $name } (innebygd)

## Other windows

# review: new
mac-new-folder-button = Ny mappe…
# review: new
mac-edit-link = Rediger lenke…
