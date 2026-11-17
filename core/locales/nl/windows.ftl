# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic blijft op de achtergrond controleren op nieuwe e-mail. Klik op het pictogram om het te openen. Klik met de rechtermuisknop op het pictogram en gebruik het menu om af te sluiten.
win-default-app-not-installed = Inbox Classic is nog niet op deze computer geïnstalleerd. Installeer het programma om het in Windows als e-mailapp te kunnen kiezen.
win-default-app-settings = Windows opent de instellingen voor Standaard-apps. Kies Inbox Classic om MAILTO-links te openen.
win-no-unread = Geen ongelezen berichten
win-unread-messages = { $count ->
    [one] { $count } ongelezen bericht
   *[other] { $count } ongelezen berichten
}
win-print-failed = Het bericht kon niet worden afgedrukt.
win-print-title-of = Afdrukken - { $subject }
win-no-bodies = De inhoud van berichten kan niet worden weergegeven.
win-webview-failed = WebView2 kon niet worden gestart.
win-webview-missing = De WebView2-runtime is niet beschikbaar.
win-list-loading = Laden...

## Buttons and words used in many windows

win-delete-button = &Verwijderen
win-find-label = &Zoeken:
win-save-as-button = Opslaan &als...
win-too-many-files = Te veel bestanden tegelijk: kies er minder.

## The Outbox


## The compose window

win-editor-failed = Er kunnen geen berichten worden geschreven.
win-ctrl-click-to-open = ({ $ctrl }+klik om te openen)
win-format-bold = Vet ({ $ctrl }+B)
win-format-italic = Cursief ({ $ctrl }+I)
win-format-underline = Onderstrepen ({ $ctrl }+U)
win-format-link = Hyperlink ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Handtekening: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Geen resultaten voor “{ $words }” in alle mappen
    [one] { $count } resultaat voor “{ $words }” in alle mappen
   *[other] { $count } resultaten voor “{ $words }” in alle mappen
}
win-search-found-in = { $count ->
    [0] Geen resultaten voor “{ $words }” in { $folder }
    [one] { $count } resultaat voor “{ $words }” in { $folder }
   *[other] { $count } resultaten voor “{ $words }” in { $folder }
}
win-search-indexing = { $count ->
    [one] de tekst van { $count } bericht wordt nog geïndexeerd
   *[other] de tekst van { $count } berichten wordt nog geïndexeerd
}
win-no-match-indexing = { $count ->
    [one] De tekst van { $count } bericht wordt nog geïndexeerd, dus er kunnen nog meer zoekresultaten verschijnen.
   *[other] De tekst van { $count } berichten wordt nog geïndexeerd, dus er kunnen nog meer zoekresultaten verschijnen.
}
win-files = { $count ->
    [one] { $count } bestand
   *[other] { $count } bestanden
}
win-click-to-retry = Klik hier om het opnieuw te proberen.
win-save-attachments = Bijlagen op&slaan...
win-files-not-saved = Opslaan mislukt voor { $failed } van de { $count } bestanden.
win-new-folder-in-highlighted = De nieuwe map wordt gemaakt in de geselecteerde map.
win-delete-folder-ask = De map “{ $folder }” verwijderen, inclusief alle berichten en submappen? De map wordt ook van de server verwijderd.
win-rename = Hern&oemen...
win-messages-not-saved = De berichten konden niet worden opgeslagen.
win-messages-not-forwarded = De berichten konden niet worden doorgestuurd.

## Accounts

win-sign-in-google = Inloggen met Google
win-sign-in-microsoft = Aanmelden met Microsoft
win-next = &Volgende >
win-your-account = je account
win-browser-sign-in = (aanmelden via browser)
win-add = &Toevoegen...
win-properties-button = &Eigenschappen...
win-signature-button = &Handtekening...
win-sign-in-apps-button = Aanmeld&apps...

## AI agents

win-dont-allow = &Niet toestaan
win-col-address = Adres
win-never-written-to = Nog niet eerder gemaild
win-book-find-label = Typ een naam of e-mailadres:
win-send = &Verzenden
win-dont-send = &Niet verzenden
win-forget-program-ask = Dit programma verwijderen, met de machtigingen en de activiteitengeschiedenis van de agents? Bij de volgende verbinding wordt opnieuw om toestemming gevraagd.
win-clear-log-ask = De activiteitengeschiedenis van de agents wissen? Wijzigingen die de agents hebben gemaakt, worden hiermee niet ongedaan gemaakt.
win-agent-programs = &Programma’s waarvan agents toegang tot je e-mail hebben gevraagd:
win-change = Wi&jzigen...
win-what-agents-did = &Activiteit van agents:
win-how-to-connect = Een agent verbinden

## Sign-in apps

win-built-in = (ingebouwd)
win-edit = &Bewerken...

## Options

win-folders-hide = De mappenlijst verbergen
win-folders-pin = De mappenlijst vastzetten naast de berichten
win-folders-show = De mappenlijst weergeven

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Inbox Classic starten
win-installer-welcome-new =
    Hiermee installeer je Inbox Classic { $version }, een e-mailprogramma.

    Het programma wordt alleen voor jouw gebruikersaccount geïnstalleerd. Je hebt geen beheerdersrechten nodig.
win-installer-welcome-same =
    Inbox Classic { $version } is al geïnstalleerd. Hiermee installeer je het opnieuw.

    Je accounts en e-mail blijven behouden.
win-installer-welcome-update =
    Hiermee werk je Inbox Classic bij van versie { $installed } naar { $version }.

    Als Inbox Classic nog geopend is, wordt het eerst afgesloten. Je accounts en e-mail blijven behouden.
win-installer-older-ask = Inbox Classic { $installed } is geïnstalleerd en is nieuwer dan { $version }. Toch de oudere versie installeren?
win-installer-still-running = Inbox Classic is nog geopend. Sluit het programma af en probeer het opnieuw.
win-installer-remove-mail-ask = Ook de accounts en de e-mail verwijderen die Inbox Classic op deze computer bewaart? De e-mail op de servers blijft staan.
