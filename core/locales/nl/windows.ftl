# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic blijft op de achtergrond controleren op nieuwe e-mail. Klik op het pictogram om het te openen. Klik met de rechtermuisknop op het pictogram en gebruik het menu om af te sluiten.
# review: new
win-default-app-not-installed = Deze kopie van Inbox Classic is niet geïnstalleerd, dus Windows toont hem niet als e-mailapp. Installeer hem om hem te kunnen kiezen.
# review: new
win-default-app-settings = Windows opent de instellingen voor Standaard-apps. Kies Inbox Classic om MAILTO-links te openen.
# review: new
win-no-unread = Geen ongelezen berichten
# review: new
win-unread-messages = { $count ->
    [one] { $count } ongelezen bericht
   *[other] { $count } ongelezen berichten
}
# review: new
win-print-failed = Het bericht kan niet worden afgedrukt.
# review: new
win-print-title-of = Afdrukken - { $subject }
# review: new
win-no-bodies = De inhoud van berichten kan niet worden weergegeven.
# review: new
win-webview-failed = Het maken van de WebView2 is mislukt.
# review: new
win-webview-missing = De WebView2-runtime is niet beschikbaar.
# review: new
win-list-loading = Laden...

## Buttons and words used in many windows

# review: new
win-delete-button = &Verwijderen
# review: new
win-find-label = &Zoeken:
# review: new
win-save-as-button = Opslaan &als...
# review: new
win-too-many-files = Te veel bestanden tegelijk: kies er minder.

## The Outbox


## The compose window

# review: new
win-editor-failed = Er kunnen geen berichten worden geschreven.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+klik om te openen)
# review: new
win-format-bold = Vet ({ $ctrl }+B)
# review: new
win-format-italic = Cursief ({ $ctrl }+I)
# review: new
win-format-underline = Onderstrepen ({ $ctrl }+U)
# review: new
win-format-link = Hyperlink ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Handtekening: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Geen resultaten voor “{ $words }” in alle mappen
    [one] { $count } resultaat voor “{ $words }” in alle mappen
   *[other] { $count } resultaten voor “{ $words }” in alle mappen
}
# review: new
win-search-found-in = { $count ->
    [0] Geen resultaten voor “{ $words }” in { $folder }
    [one] { $count } resultaat voor “{ $words }” in { $folder }
   *[other] { $count } resultaten voor “{ $words }” in { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] de tekst van { $count } bericht wordt nog geïndexeerd
   *[other] de tekst van { $count } berichten wordt nog geïndexeerd
}
# review: new
win-no-match-indexing = { $count ->
    [one] De tekst van { $count } bericht wordt nog geïndexeerd, dus er wordt misschien binnenkort meer gevonden.
   *[other] De tekst van { $count } berichten wordt nog geïndexeerd, dus er wordt misschien binnenkort meer gevonden.
}
# review: new
win-files = { $count ->
    [one] { $count } bestand
   *[other] { $count } bestanden
}
# review: new
win-click-to-retry = Klik hier om het opnieuw te proberen.
# review: new
win-save-attachments = Bijlagen op&slaan...
# review: new
win-files-not-saved = { $failed } van de { $count } bestanden konden niet worden opgeslagen.
# review: new
win-new-folder-in-highlighted = De nieuwe map wordt gemaakt in de geselecteerde map.
# review: new
win-delete-folder-ask = De map “{ $folder }” verwijderen, met de berichten en de mappen erin? Hij wordt ook op de server verwijderd.
# review: new
win-rename = &Hernoemen...
# review: new
win-messages-not-saved = De berichten kunnen niet worden opgeslagen.
# review: new
win-messages-not-forwarded = De berichten kunnen niet worden doorgestuurd.

## Accounts

# review: new
win-sign-in-google = Inloggen met Google
# review: new
win-sign-in-microsoft = Aanmelden met Microsoft
# review: new
win-next = &Volgende >
# review: new
win-your-account = je account
# review: new
win-browser-sign-in = (aanmelden via browser)
# review: new
win-add = &Toevoegen...
# review: new
win-properties-button = &Eigenschappen...
# review: new
win-signature-button = &Handtekening...
# review: new
win-sign-in-apps-button = Aanmeld&apps...

## AI agents

# review: new
win-dont-allow = &Niet toestaan
# review: new
win-col-address = Adres
# review: new
win-never-written-to = Nooit aan geschreven
# review: new
win-book-find-label = Typ een naam of e-mailadres:
# review: new
win-send = &Verzenden
# review: new
win-dont-send = &Niet verzenden
# review: new
win-forget-program-ask = Dit programma verwijderen, met de machtigingen en de activiteitengeschiedenis van de agents? Bij de volgende verbinding wordt opnieuw om toestemming gevraagd.
# review: new
win-clear-log-ask = De activiteitengeschiedenis van de agents wissen? Wijzigingen die de agents hebben gemaakt, worden hiermee niet ongedaan gemaakt.
# review: new
win-agent-programs = &Programma’s waarvan agents toegang tot je e-mail hebben gevraagd:
# review: new
win-change = &Wijzigen...
# review: new
win-what-agents-did = &Activiteit van agents:
# review: new
win-how-to-connect = Hoe verbind ik een agent

## Sign-in apps

# review: new
win-built-in = (ingebouwd)
# review: new
win-edit = &Bewerken...

## Options

# review: new
win-folders-hide = De mappenlijst verbergen
# review: new
win-folders-pin = De mappenlijst naast de berichten houden
# review: new
win-folders-show = De mappen tonen

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Inbox Classic starten
# review: new
win-installer-welcome-new =
    Hiermee installeer je Inbox Classic { $version }, een e-mailprogramma.

    Er zijn geen beheerdersrechten nodig: het wordt alleen voor jouw account geïnstalleerd.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } is al geïnstalleerd. Hiermee installeer je het opnieuw.

    Je accounts en e-mail blijven behouden.
# review: new
win-installer-welcome-update =
    Hiermee werk je Inbox Classic { $installed } bij naar { $version }.

    Als het actief is, wordt het eerst gesloten. Je accounts en e-mail blijven behouden.
# review: new
win-installer-older-ask = Inbox Classic { $installed } is geïnstalleerd en is nieuwer dan { $version }. Toch de oudere versie installeren?
# review: new
win-installer-still-running = Inbox Classic is nog actief. Sluit het en probeer het opnieuw.
# review: new
win-installer-remove-mail-ask = Ook de accounts en de e-mail verwijderen die Inbox Classic op deze computer bewaart? De e-mail op de servers blijft staan.
