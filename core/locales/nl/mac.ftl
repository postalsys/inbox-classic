# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Mac conventions in Dutch: an ellipsis (…) after a command that asks for more,
# the menu words as macOS writes them in Dutch, curly quotes and apostrophes.

## The app and its menus

# review: new
mac-quit = Stop Inbox Classic
# review: new
mac-settings = Instellingen…
# review: new
mac-services = Voorzieningen
# review: new
mac-hide = Verberg Inbox Classic
# review: new
mac-hide-others = Verberg andere
# review: new
mac-show-all = Toon alles
# review: new
mac-check-updates = Controleer op updates…
# review: new
mac-close-window = Sluit venster
# review: new
mac-redo = Opnieuw
# review: new
mac-cut = Knip
# review: new
mac-paste = Plak
# review: new
mac-menu-window = Venster
# review: new
mac-minimize = Minimaliseer
# review: new
mac-zoom = Zoom
# review: new
mac-no-updates = Deze versie van Inbox Classic ondersteunt geen automatische updates. Download de nieuwste versie van inboxclassic.com.

## Settings

# review: new
mac-settings-title = Instellingen
# review: new
mac-language-label = Taal:
# review: new
mac-restart-hint = Start Inbox Classic opnieuw om de taal te wijzigen.
# review: new
mac-notify-new-mail = Melding geven wanneer er nieuwe e-mail binnenkomt
# review: new
mac-restart-question = Inbox Classic nu opnieuw starten om de taal te wijzigen?

## Dialogs

# review: new
mac-choose = Kies

## The main window

# review: new
mac-still-running-detail = Inbox Classic blijft op de achtergrond controleren op nieuwe e-mail. Klik op het symbool in het Dock om de app te openen.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } bericht in Postvak UIT
       *[other] { $count } berichten in Postvak UIT
    }
# review: new
mac-sending = { $subject } wordt verzonden…
# review: new
mac-checking = Controleren op nieuwe berichten in { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Deze kopie van Inbox Classic is geen app-bundel, dus hij kan niet de standaard-e-mailapp zijn.
# review: new
mac-not-made-default = Inbox Classic is niet ingesteld als standaard-e-mailapp: { $reason }
# review: new
mac-tool-search = Zoek

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] De tekst van { $count } bericht wordt nog geïndexeerd, dus er wordt misschien binnenkort meer gevonden.
       *[other] De tekst van { $count } berichten wordt nog geïndexeerd, dus er wordt misschien binnenkort meer gevonden.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Geen resultaten voor “{ $words }” in alle mappen
        [one] { $count } resultaat voor “{ $words }” in alle mappen
       *[other] { $count } resultaten voor “{ $words }” in alle mappen
    }
# review: new
mac-results-in =
    { $count ->
        [0] Geen resultaten voor “{ $words }” in { $folder }
        [one] { $count } resultaat voor “{ $words }” in { $folder }
       *[other] { $count } resultaten voor “{ $words }” in { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] de tekst van { $count } bericht wordt nog geïndexeerd
       *[other] de tekst van { $count } berichten wordt nog geïndexeerd
    }
# review: new
mac-folder-unread = { $folder }, { $count } ongelezen
# review: new
mac-import-messages = Importeer berichten
# review: new
mac-save-messages = Bewaar berichten
# review: new
mac-save-attachments-menu = Bewaar bijlagen…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $failed } van de { $count } bestanden konden niet worden bewaard.
    }
# review: new
mac-no-calendar-app = Er is op deze Mac geen agenda-app om uitnodigingen (.ics-bestanden) mee te openen.
# review: new
mac-file-not-saved = Het bestand kon niet worden bewaard.
# review: new
mac-unsubscribing = Afmelden bij { $target }…

## The compose window

# review: new
mac-bold = Vet
# review: new
mac-italic = Cursief
# review: new
mac-underline = Onderstreept
# review: new
mac-bcc = Bcc
# review: new
mac-command-click-to-open = ⌘-klik om te openen
# review: new
mac-saving-to-drafts = Opslaan in Concepten…
# review: new
mac-dont-save = Niet bewaren

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } bestand
       *[other] { $count } bestanden
    }

## Accounts

# review: new
mac-next = Volgende
# review: new
mac-name-placeholder = Anne de Vries
# review: new
mac-more-sign-in-options = Meer aanmeldopties…
# review: new
mac-add-sign-in-app = Aanmeldapp toevoegen…
# review: new
mac-looking-up = De instellingen van { $domain } worden opgezocht…
# review: new
mac-add-button = Voeg toe…
# review: new
mac-properties-button = Eigenschappen…
# review: new
mac-signature-button = Handtekening…
# review: new
mac-security-button = Beveiliging…
# review: new
mac-sign-in-apps-button = Aanmeldapps…

## AI agents

# review: new
mac-forget-program = Dit programma en de activiteitengeschiedenis van de agents verwijderen?
# review: new
mac-forget-program-detail = De machtigingen van het programma worden verwijderd. Bij de volgende verbinding wordt opnieuw om toestemming gevraagd.

## Sign-in apps

# review: new
mac-checking-issuer = { $issuer } controleren…
# review: new
mac-edit-button = Wijzig…
# review: new
mac-use-for-new-accounts = { $name } gebruiken voor nieuwe accounts
# review: new
mac-built-in = { $name } (ingebouwd)

## Other windows

# review: new
mac-new-folder-button = Nieuwe map…
# review: new
mac-edit-link = Wijzig link…
