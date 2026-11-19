# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Voorkeuren, Afsluiten).

## The main window

gtk-search-looks-in = In { $place } wordt gezocht in onderwerpen, afzenders, ontvangers, bijlagenamen en berichttekst. Controleer de spelling of probeer minder zoekwoorden.
gtk-search-still-indexing = { $count ->
    [one] De tekst van { $count } bericht wordt nog geïndexeerd. Er verschijnen misschien binnenkort meer resultaten.
   *[other] De tekst van { $count } berichten wordt nog geïndexeerd. Er verschijnen misschien binnenkort meer resultaten.
}
gtk-search-results-everywhere = { $count ->
    [0] Geen resultaten
    [one] { $count } resultaat
   *[other] { $count } resultaten
} voor “{ $words }” in alle mappen
gtk-search-results-in = { $count ->
    [0] Geen resultaten
    [one] { $count } resultaat
   *[other] { $count } resultaten
} voor “{ $words }” in { $place }
gtk-search-indexing = { $count ->
    [one] de tekst van { $count } bericht wordt nog geïndexeerd
   *[other] de tekst van { $count } berichten wordt nog geïndexeerd
}
gtk-list-loading = Laden...
gtk-menu-rename = Hernoemen...
gtk-import-one-question = Het bericht { $file } importeren in { $folder }?
gtk-files-not-saved = Opslaan mislukt voor { $failed } van de { $total } bestanden.
gtk-unsubscribe-one-click =
    Afmelden voor deze mailinglijst?

    Inbox Classic stuurt een afmeldverzoek naar { $target }. Er wordt geen webpagina geopend en geen e-mail verzonden.
gtk-unsubscribe-mail =
    Afmelden voor deze mailinglijst?

    Stuur een e-mail naar { $target } om je af te melden. Inbox Classic maakt die voor je klaar. Verzend het bericht om te bevestigen.
gtk-unsubscribe-web =
    Afmelden voor deze mailinglijst?

    De afmeldpagina van de mailinglijst wordt geopend in je browser ({ $target }).
gtk-unsubscribe-failed = Afmelden is mislukt: { $problem }
gtk-toolbar-create-mail-menu = Opstellen vanuit een bepaald account
gtk-toolbar-send-recv-menu = E-mail verzenden en ontvangen voor een bepaald account
gtk-main-menu = Hoofdmenu
gtk-folder-list = Mappenlijst
gtk-quit = Afsluiten

## The Move and Copy window

gtk-new-folder-at-top-of = De nieuwe map komt op het hoogste niveau van { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Geen ongelezen berichten
    [one] { $count } ongelezen bericht
   *[other] { $count } ongelezen berichten
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Er wachten geen berichten om te worden verzonden.
gtk-outbox-row = Aan: { $to }  ·  In wachtrij { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic blijft op de achtergrond controleren op nieuwe e-mail. Gebruik het pictogram in de bovenbalk om de app te openen of af te sluiten.
gtk-sign-in-again-ask =
    De aanmelding bij { $account } is geweigerd of de sessie is verlopen.

    Opnieuw aanmelden in de browser?
gtk-default-app-not-installed = Inbox Classic is nog niet op deze computer geïnstalleerd. Installeer het programma om het als e-mailapp te kunnen kiezen.
gtk-default-app-now = Inbox Classic is nu je standaard-e-mailapp: e-maillinks openen hier een nieuw bericht.
gtk-default-app-failed = Inbox Classic kon niet als standaardapp voor e-mail worden ingesteld.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Bijlagen van het bericht
gtk-files = { $count ->
    [one] { $count } bestand
   *[other] { $count } bestanden
}
gtk-pictures-blocked = Sommige afbeeldingen zijn geblokkeerd om te helpen voorkomen dat de afzender je computer herkent.
gtk-download-pictures = Afbeeldingen downloaden
gtk-save-attachments-menu = Bijlagen opslaan...

## The compose window

gtk-format-bold = Vet (Ctrl+B)
gtk-format-italic = Cursief (Ctrl+I)
gtk-format-underline = Onderstrepen (Ctrl+U)
gtk-format-hyperlink = Hyperlink (Ctrl+K)
gtk-font = Lettertype
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Opslaan (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+klik om te openen)

## Accounts

gtk-plain-warning =
    Zonder versleuteling kan iedereen die je netwerkverkeer onderschept je wachtwoord en berichten lezen. Gebruik deze verbinding alleen met een server op je eigen computer of lokale netwerk.

    Doorgaan?
gtk-account-name-title = Accountnaam
gtk-display-name-title = Weergavenaam
gtk-turned-off-why = De optie “{ $button }” is uitgeschakeld op deze computer. { $reason }
gtk-turned-off-why-long =
    De optie “{ $button }” is uitgeschakeld op deze computer.

    { $reason }
gtk-next = Volgende >
gtk-provider-sign-in = Meld je aan bij { $address } op de website van { $provider }. Je wachtwoord wordt niet gedeeld met Inbox Classic. Als je account app-wachtwoorden voor e-mail ondersteunt, kun je er een maken in de beveiligingsinstellingen. Voor Outlook.com en Microsoft 365 moet je je aanmelden via de browser.
gtk-provider-sign-in-apps = Meld je aan bij { $address } op de website van { $provider } met een van je aanmeldapps (Meer aanmeldopties). Als je account app-wachtwoorden voor e-mail ondersteunt, kun je er een maken in de beveiligingsinstellingen. Voor Outlook.com en Microsoft 365 moet je je aanmelden via de browser.
gtk-accounts-add = Toevoegen...
gtk-accounts-properties = Eigenschappen...
gtk-accounts-signature = Handtekening...
gtk-accounts-sign-in-apps = Aanmeldapps...

## Sign-in apps

gtk-app-server = Server voor { $kind }
gtk-app-port = Poort voor { $kind }
gtk-app-security = Beveiliging voor { $kind }
gtk-issuer-found =
    Aanmeldpagina: { $page }
    Token-endpoint: { $endpoint }
gtk-client-id = Client-ID
gtk-client-secret = Clientgeheim
gtk-scopes = Machtigingen (scopes)
gtk-redirect-uri = Omleidings-URI
gtk-issuer-usable =
    De uitgever kan worden gebruikt.

    { $found }
gtk-app-built-in = { $app } is ingebouwd. Je kunt alleen kiezen of deze wordt aangeboden voor nieuwe accounts. { $reason }
gtk-built-in = { $app } (ingebouwd)
gtk-offered-for-new = Aangeboden voor nieuwe accounts
gtk-edit-button = Bewerken...
gtk-remove-app-ask = De aanmeldapp { $app } en het opgeslagen clientgeheim verwijderen?
gtk-sign-in-apps-intro = Met aanmeldapps melden accounts zich aan via de browser. Een app die is uitgeschakeld, wordt niet aangeboden voor nieuwe accounts; accounts die hem al gebruiken, blijven werken.

## AI agents

gtk-agent-it-may = Toegestane acties
gtk-agent-accounts = Toegestane accounts
gtk-never-used = Nooit gebruikt
gtk-last-used = Laatst gebruikt: { $date }
gtk-forget-program = Dit programma uit de lijst verwijderen?
gtk-forget-program-detail = De machtigingen van het programma en de activiteitengeschiedenis van de agents worden verwijderd. Bij de volgende verbinding wordt opnieuw om toestemming gevraagd.
gtk-no-agents-yet = Nog geen agent heeft gevraagd om je e-mail te gebruiken.
gtk-nothing-yet = Nog niets.

## Preferences

gtk-preferences = Voorkeuren
gtk-notify-subtitle = Alleen als Inbox Classic op de achtergrond staat

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = E-mailprogramma
gtk-desktop-comment = E-mail lezen en schrijven: een snel, eenvoudig e-mailprogramma
gtk-desktop-keywords = e-mail;post;postvak;berichten;
gtk-metainfo-summary = Een snel, eenvoudig e-mailprogramma
gtk-metainfo-description = Inbox Classic is een e-mailprogramma met een vertrouwde indeling: mappen links, de berichtenlijst bovenaan en het geselecteerde bericht eronder. Het werkt met IMAP- en SMTP-accounts. Bij Outlook.com en Microsoft 365 meld je je aan via de browser.
gtk-metainfo-feature-sanitized = Berichten worden weergegeven zonder scripts; afbeeldingen van internet worden alleen geladen als je dat toestaat
gtk-metainfo-feature-search = Zoeken in onderwerp, afzender, ontvangers, bijlagenamen en berichttekst, met de zoekoperatoren van Gmail
gtk-metainfo-feature-replies = Geciteerde eerdere berichten in antwoorden worden ingeklapt
gtk-metainfo-feature-offline = Lees e-mail offline zolang de lokale kopie bewaard blijft; aanmeldgegevens staan normaal in de beveiligde systeemopslag, als die beschikbaar is
