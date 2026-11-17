# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Voorkeuren, Afsluiten).

## The main window

# review: new
gtk-search-looks-in = Er is in { $place } gezocht in onderwerpen, afzenders, ontvangers, namen van bijlagen en de tekst van berichten. Controleer de spelling of probeer minder woorden.
# review: new
gtk-search-still-indexing = { $count ->
    [one] De tekst van { $count } bericht wordt nog geïndexeerd. Er verschijnen misschien binnenkort meer resultaten.
   *[other] De tekst van { $count } berichten wordt nog geïndexeerd. Er verschijnen misschien binnenkort meer resultaten.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Geen resultaten
    [one] { $count } resultaat
   *[other] { $count } resultaten
} voor “{ $words }” in alle mappen
# review: new
gtk-search-results-in = { $count ->
    [0] Geen resultaten
    [one] { $count } resultaat
   *[other] { $count } resultaten
} voor “{ $words }” in { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] de tekst van { $count } bericht wordt nog geïndexeerd
   *[other] de tekst van { $count } berichten wordt nog geïndexeerd
}
# review: new
gtk-list-loading = Laden...
# review: new
gtk-menu-rename = Hernoemen...
# review: new
gtk-import-one-question = Het bericht { $file } importeren in { $folder }?
# review: new
gtk-files-not-saved = { $failed } van de { $total } bestanden konden niet worden opgeslagen.
# review: new
gtk-unsubscribe-one-click =
    Afmelden voor deze mailinglijst?

    Inbox Classic stuurt een afmeldverzoek naar { $target }. Er wordt geen webpagina geopend en geen e-mail verzonden.
# review: new
gtk-unsubscribe-mail =
    Afmelden voor deze mailinglijst?

    Stuur een e-mail naar { $target } om je af te melden. Inbox Classic maakt die voor je klaar. Verzend het bericht om te bevestigen.
# review: new
gtk-unsubscribe-web =
    Afmelden voor deze mailinglijst?

    De afmeldpagina van de mailinglijst wordt geopend in je browser ({ $target }).
# review: new
gtk-unsubscribe-failed = Afmelden is mislukt: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Opstellen vanuit een bepaald account
# review: new
gtk-toolbar-send-recv-menu = E-mail verzenden en ontvangen voor een bepaald account
# review: new
gtk-main-menu = Hoofdmenu
# review: new
gtk-folder-list = Mappenlijst
# review: new
gtk-quit = Afsluiten

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = De nieuwe map komt op het hoogste niveau van { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Geen ongelezen berichten
    [one] { $count } ongelezen bericht
   *[other] { $count } ongelezen berichten
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Er wachten geen berichten om te worden verzonden.
# review: new
gtk-outbox-row = Aan: { $to }  ·  In wachtrij { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic blijft op de achtergrond controleren op nieuwe e-mail. Gebruik het pictogram in de bovenbalk om de app te openen of af te sluiten.
# review: new
gtk-sign-in-again-ask =
    De aanmelding bij { $account } is geweigerd of de sessie is verlopen.

    Opnieuw aanmelden in de browser?
# review: new
gtk-default-app-not-installed = Deze kopie van Inbox Classic is niet geïnstalleerd, dus het systeem toont hem niet als e-mailapp. Installeer hem om hem te kunnen kiezen.
# review: new
gtk-default-app-now = Inbox Classic is nu je standaard-e-mailapp: e-maillinks openen hier een nieuw bericht.
# review: new
gtk-default-app-failed = Inbox Classic kan niet worden ingesteld als standaard-e-mailapp.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Datum:
# review: new
gtk-reader-files = Bijlagen van het bericht
# review: new
gtk-files = { $count ->
    [one] { $count } bestand
   *[other] { $count } bestanden
}
# review: new
gtk-pictures-blocked = Sommige afbeeldingen zijn geblokkeerd, zodat de afzender je computer niet kan herkennen.
# review: new
gtk-download-pictures = Afbeeldingen downloaden
# review: new
gtk-save-attachments-menu = Bijlagen opslaan...

## The compose window

# review: new
gtk-format-bold = Vet (Ctrl+B)
# review: new
gtk-format-italic = Cursief (Ctrl+I)
# review: new
gtk-format-underline = Onderstrepen (Ctrl+U)
# review: new
gtk-format-hyperlink = Hyperlink (Ctrl+K)
# review: new
gtk-font = Lettertype
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Opslaan (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+klik om te openen)

## Accounts

# review: new
gtk-plain-warning =
    Zonder versleuteling kan iedereen die je netwerkverkeer onderschept je wachtwoord en berichten lezen. Gebruik deze verbinding alleen met een server op je eigen computer of lokale netwerk.

    Doorgaan?
# review: new
gtk-account-name-title = Accountnaam
# review: new
gtk-display-name-title = Weergavenaam
# review: new
gtk-turned-off-why = De optie “{ $button }” is uitgeschakeld op deze computer. { $reason }
# review: new
gtk-turned-off-why-long =
    De optie “{ $button }” is uitgeschakeld op deze computer.

    { $reason }
# review: new
gtk-next = Volgende >
# review: new
gtk-provider-sign-in = Meld je aan bij { $address } op de website van { $provider }. Je wachtwoord wordt niet gedeeld met Inbox Classic. Je kunt ook een app-wachtwoord gebruiken dat je in de beveiligingsinstellingen van je account hebt gemaakt.
# review: new
gtk-provider-sign-in-apps = Meld je aan bij { $address } op de website van { $provider } met een van je aanmeldapps (Meer aanmeldopties). Je kunt ook een app-wachtwoord gebruiken dat je in de beveiligingsinstellingen van je account hebt gemaakt.
# review: new
gtk-accounts-add = Toevoegen...
# review: new
gtk-accounts-properties = Eigenschappen...
# review: new
gtk-accounts-signature = Handtekening...
# review: new
gtk-accounts-sign-in-apps = Aanmeldapps...

## Sign-in apps

# review: new
gtk-app-server = { $kind }-server
# review: new
gtk-app-port = { $kind }-poort
# review: new
gtk-app-security = { $kind }-beveiliging
# review: new
gtk-issuer-found =
    Aanmeldpagina: { $page }
    Token-endpoint: { $endpoint }
# review: new
gtk-client-id = Client-ID
# review: new
gtk-client-secret = Clientgeheim
# review: new
gtk-scopes = Machtigingen (scopes)
# review: new
gtk-redirect-uri = Omleidings-URI
# review: new
gtk-issuer-usable =
    De uitgever kan worden gebruikt.

    { $found }
# review: new
gtk-app-built-in = { $app } is ingebouwd. Je kunt alleen kiezen of deze wordt aangeboden voor nieuwe accounts. { $reason }
# review: new
gtk-built-in = { $app } (ingebouwd)
# review: new
gtk-offered-for-new = Aangeboden voor nieuwe accounts
# review: new
gtk-edit-button = Bewerken...
# review: new
gtk-remove-app-ask = De aanmeldapp { $app } en het opgeslagen clientgeheim verwijderen?
# review: new
gtk-sign-in-apps-intro = Met aanmeldapps melden accounts zich aan via de browser. Een app die is uitgeschakeld, wordt niet aangeboden voor nieuwe accounts; accounts die hem al gebruiken, blijven werken.

## AI agents

# review: new
gtk-agent-it-may = Toegestane acties
# review: new
gtk-agent-accounts = Toegestane accounts
# review: new
gtk-never-used = Nooit gebruikt
# review: new
gtk-last-used = Laatst gebruikt { $date }
# review: new
gtk-forget-program = Dit programma verwijderen?
# review: new
gtk-forget-program-detail = De machtigingen van het programma en de activiteitengeschiedenis van de agents worden verwijderd. Bij de volgende verbinding wordt opnieuw om toestemming gevraagd.
# review: new
gtk-no-agents-yet = Nog geen agent heeft gevraagd om je e-mail te gebruiken.
# review: new
gtk-nothing-yet = Nog niets.

## Preferences

# review: new
gtk-preferences = Voorkeuren
# review: changed
gtk-notify-subtitle = Alleen als Inbox Classic op de achtergrond staat

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = E-mailprogramma
# review: new
gtk-desktop-comment = E-mail lezen en schrijven: een snel, eenvoudig e-mailprogramma
# review: new
gtk-desktop-keywords = e-mail;post;postvak;berichten;
# review: new
gtk-metainfo-summary = Een snel, eenvoudig e-mailprogramma
# review: new
gtk-metainfo-description = Inbox Classic leest en schrijft e-mail met de mappen links, de berichten bovenaan en het bericht daaronder, zoals e-mailprogramma’s vroeger deden. Het werkt met elk IMAP- en SMTP-account en meldt zich via de browser aan bij Outlook.com en Microsoft 365.
# review: new
gtk-metainfo-feature-sanitized = Elk bericht wordt opgeschoond getoond, zonder scripts, en afbeeldingen van internet alleen als je dat toestaat
# review: new
gtk-metainfo-feature-search = Zoeken naar woorden in het onderwerp, de personen, de bestandsnamen en de tekst, met de zoekoperatoren van Gmail
# review: new
gtk-metainfo-feature-replies = Antwoorden vouwen de eerdere berichten die ze citeren weg
# review: new
gtk-metainfo-feature-offline = E-mail blijft offline leesbaar; wachtwoorden worden bewaard in je sleutelbos
