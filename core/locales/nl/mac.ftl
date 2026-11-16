# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Mac conventions in Dutch: an ellipsis (…) after a command that asks for more,
# the menu words as macOS writes them in Dutch, curly quotes and apostrophes.

## The app and its menus

mac-quit = Stop Inbox Classic
mac-settings = Instellingen…
mac-services = Voorzieningen
mac-hide = Verberg Inbox Classic
mac-hide-others = Verberg andere
mac-show-all = Toon alles
mac-check-updates = Controleer op updates…
mac-close-window = Sluit venster
mac-redo = Opnieuw
mac-cut = Knip
mac-paste = Plak
mac-menu-window = Venster
mac-minimize = Minimaliseer
mac-zoom = Zoom
mac-no-updates = Deze versie van Inbox Classic ondersteunt geen automatische updates. Download de nieuwste versie van inboxclassic.com.

## Settings

mac-settings-title = Instellingen
mac-language-label = Taal:
mac-restart-hint = Start Inbox Classic opnieuw om de taal te wijzigen.
mac-notify-new-mail = Melding geven wanneer er nieuwe e-mail binnenkomt
mac-restart-question = Inbox Classic nu opnieuw starten om de taal te wijzigen?

## Dialogs

mac-choose = Kies

## The main window

mac-still-running-detail = Inbox Classic blijft op de achtergrond controleren op nieuwe e-mail. Klik op het symbool in het Dock om de app te openen.
mac-outbox-waiting =
    { $count ->
        [one] { $count } bericht in Postvak UIT
       *[other] { $count } berichten in Postvak UIT
    }
mac-sending = { $subject } wordt verzonden…
mac-checking = Controleren op nieuwe berichten in { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Deze versie van Inbox Classic is geen appbundel en kan daarom niet als standaardapp voor e-mail worden ingesteld.
mac-not-made-default = Inbox Classic kon niet als standaardapp voor e-mail worden ingesteld: { $reason }
mac-tool-search = Zoek

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] De tekst van { $count } bericht wordt nog geïndexeerd, dus er kunnen nog meer zoekresultaten verschijnen.
       *[other] De tekst van { $count } berichten wordt nog geïndexeerd, dus er kunnen nog meer zoekresultaten verschijnen.
    }
mac-results-everywhere =
    { $count ->
        [0] Geen resultaten voor “{ $words }” in alle mappen
        [one] { $count } resultaat voor “{ $words }” in alle mappen
       *[other] { $count } resultaten voor “{ $words }” in alle mappen
    }
mac-results-in =
    { $count ->
        [0] Geen resultaten voor “{ $words }” in { $folder }
        [one] { $count } resultaat voor “{ $words }” in { $folder }
       *[other] { $count } resultaten voor “{ $words }” in { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] de tekst van { $count } bericht wordt nog geïndexeerd
       *[other] de tekst van { $count } berichten wordt nog geïndexeerd
    }
mac-folder-unread = { $folder }, { $count } ongelezen
mac-import-messages = Importeer berichten
mac-save-messages = Bewaar berichten
mac-save-attachments-menu = Bewaar bijlagen…
mac-files-not-saved =
    { $count ->
       *[other] Bewaren mislukt voor { $failed } van de { $count } bestanden.
    }
mac-no-calendar-app = Er is op deze Mac geen agenda-app om uitnodigingen (.ics-bestanden) mee te openen.
mac-file-not-saved = Het bestand kon niet worden bewaard.
mac-unsubscribing = Afmelden bij { $target }…
mac-loading-list = Laden…

## The compose window

mac-bold = Vet
mac-italic = Cursief
mac-underline = Onderstreept
mac-bcc = Bcc
mac-command-click-to-open = ⌘-klik om te openen
mac-saving-to-drafts = Bewaren in Concepten…
mac-dont-save = Niet bewaren

## The reading pane

mac-files =
    { $count ->
        [one] { $count } bestand
       *[other] { $count } bestanden
    }

## Accounts

mac-next = Volgende
mac-name-placeholder = Anne de Vries
mac-more-sign-in-options = Meer aanmeldopties…
mac-add-sign-in-app = Voeg aanmeldapp toe…
mac-looking-up = De instellingen van { $domain } worden opgezocht…
mac-add-button = Voeg toe…
mac-properties-button = Eigenschappen…
mac-signature-button = Handtekening…
mac-security-button = Beveiliging…
mac-sign-in-apps-button = Aanmeldapps…

## AI agents

mac-forget-program = Dit programma en de activiteitengeschiedenis van de agents verwijderen?
mac-forget-program-detail = De machtigingen van het programma worden verwijderd. Bij de volgende verbinding wordt opnieuw om toestemming gevraagd.

## Sign-in apps

mac-checking-issuer = { $issuer } controleren…
mac-edit-button = Wijzig…
mac-use-for-new-accounts = { $name } gebruiken voor nieuwe accounts
mac-built-in = { $name } (ingebouwd)

## Other windows

mac-new-folder-button = Nieuwe map…
mac-edit-link = Wijzig link…
