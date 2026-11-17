# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Indstillinger, Afslut).

## The main window

gtk-search-looks-in = Søgningen i { $place } omfatter emner, afsendere, modtagere, navne på vedhæftede filer og meddelelsestekst. Kontrollér stavningen, eller prøv med færre ord.
gtk-search-still-indexing = { $count ->
    [one] Teksten i 1 meddelelse indekseres stadig. Der kan snart dukke flere resultater op.
   *[other] Teksten i { $count } meddelelser indekseres stadig. Der kan snart dukke flere resultater op.
}
gtk-search-results-everywhere = { $count ->
    [0] Ingen resultater
    [one] 1 resultat
   *[other] { $count } resultater
} for »{ $words }« i alle mapper
gtk-search-results-in = { $count ->
    [0] Ingen resultater
    [one] 1 resultat
   *[other] { $count } resultater
} for »{ $words }« i { $place }
gtk-search-indexing = { $count ->
    [one] indekserer stadig teksten i 1 meddelelse
   *[other] indekserer stadig teksten i { $count } meddelelser
}
gtk-list-loading = Indlæser...
gtk-menu-rename = Omdøb...
gtk-import-one-question = Vil du importere meddelelsen { $file } til { $folder }?
gtk-files-not-saved = { $total ->
    [one] Filen kunne ikke gemmes.
   *[other] { $failed } af de { $total } filer kunne ikke gemmes.
}
gtk-unsubscribe-one-click =
    Vil du afmelde denne mailingliste?

    Inbox Classic sender en afmeldingsanmodning til { $target }. Der åbnes ingen webside, og der sendes ingen e-mail.
gtk-unsubscribe-mail =
    Vil du afmelde denne mailingliste?

    For at afmelde skal du sende en e-mail til { $target }. Inbox Classic gør meddelelsen klar. Send den for at bekræfte afmeldingen.
gtk-unsubscribe-web =
    Vil du afmelde denne mailingliste?

    Mailinglistens afmeldingsside åbnes i din browser ({ $target }).
gtk-unsubscribe-failed = Kunne ikke afmelde: { $problem }
gtk-toolbar-create-mail-menu = Skriv fra en bestemt konto
gtk-toolbar-send-recv-menu = Send og modtag mail for en bestemt konto
gtk-main-menu = Hovedmenu
gtk-folder-list = Mappeliste
gtk-quit = Afslut

## The Move and Copy window

gtk-new-folder-at-top-of = Den nye mappe oprettes på øverste niveau i kontoen { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Ingen ulæste meddelelser
    [one] 1 ulæst meddelelse
   *[other] { $count } ulæste meddelelser
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Der er ingen meddelelser, der venter på at blive sendt.
gtk-outbox-row = Til: { $to }  ·  I kø { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic bliver ved med at søge efter ny mail i baggrunden. Brug programmets ikon i toppanelet til at åbne eller afslutte programmet.
gtk-sign-in-again-ask =
    Login på { $account } blev afvist, eller sessionen er udløbet.

    Vil du logge på igen i browseren?
gtk-default-app-not-installed = Inbox Classic skal installeres, før systemet kan tilbyde det som standardmailprogram.
gtk-default-app-now = Inbox Classic er nu dit standardmailprogram: e-maillinks åbner en ny meddelelse her.
gtk-default-app-failed = Inbox Classic kunne ikke gøres til standardmailprogram.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Dato:
gtk-reader-files = Vedhæftede filer
gtk-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
gtk-pictures-blocked = Nogle billeder er blokeret for at begrænse afsenderens mulighed for at spore dig.
gtk-download-pictures = Hent billeder
gtk-save-attachments-menu = Gem vedhæftede filer...

## The compose window

gtk-format-bold = Fed (Ctrl+B)
gtk-format-italic = Kursiv (Ctrl+I)
gtk-format-underline = Understreget (Ctrl+U)
gtk-format-hyperlink = Link (Ctrl+K)
gtk-font = Skrifttype
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Gem (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+klik for at åbne)

## Accounts

gtk-plain-warning =
    Uden kryptering kan alle, der opsnapper din netværkstrafik, læse din adgangskode og dine meddelelser. Brug kun denne forbindelse med en server på din egen computer eller dit lokale netværk.

    Vil du fortsætte?
gtk-account-name-title = Kontonavn
gtk-display-name-title = Vist navn
gtk-turned-off-why = Muligheden »{ $button }« er slået fra på denne computer. { $reason }
gtk-turned-off-why-long =
    Muligheden »{ $button }« er slået fra på denne computer.

    { $reason }
gtk-next = Næste >
# review: changed
gtk-provider-sign-in = Log på { $address } på webstedet for { $provider }. Din adgangskode deles ikke med Inbox Classic. Du kan også bruge en appadgangskode, som du opretter i kontoens sikkerhedsindstillinger.
# review: changed
gtk-provider-sign-in-apps = Log på { $address } på webstedet for { $provider } med en af dine login-apps (Flere loginmuligheder). Du kan også bruge en appadgangskode, som du opretter i kontoens sikkerhedsindstillinger.
gtk-accounts-add = Tilføj...
gtk-accounts-properties = Egenskaber...
gtk-accounts-signature = Signatur...
gtk-accounts-sign-in-apps = Login-apps...

## Sign-in apps

gtk-app-server = { $kind }-server
gtk-app-port = { $kind }-port
gtk-app-security = { $kind }-sikkerhed
gtk-issuer-found =
    Loginside: { $page }
    Token-endpoint: { $endpoint }
gtk-client-id = Klient-id
gtk-client-secret = Klienthemmelighed
gtk-scopes = Tilladelser (scopes)
gtk-redirect-uri = Omdirigerings-URI
gtk-issuer-usable =
    Udstederen kan bruges.

    { $found }
gtk-app-built-in = { $app } er indbygget. Du kan kun ændre, om den tilbydes til nye konti. { $reason }
gtk-built-in = { $app } (indbygget)
gtk-offered-for-new = Tilbydes til nye konti
gtk-edit-button = Rediger...
gtk-remove-app-ask = Vil du fjerne login-appen { $app } og dens gemte klienthemmelighed?
gtk-sign-in-apps-intro = Med login-apps kan du logge på dine konti via browseren. Apps, der er slået fra, tilbydes ikke til nye konti. Konti, der allerede bruger dem, fungerer fortsat.

## AI agents

gtk-agent-it-may = Tilladte handlinger
gtk-agent-accounts = Tilladte konti
gtk-never-used = Aldrig brugt
gtk-last-used = Senest brugt { $date }
gtk-forget-program = Vil du fjerne dette program?
gtk-forget-program-detail = Programmets tilladelser og dets agenters aktivitetshistorik slettes. Du bliver spurgt om tilladelse igen, næste gang det opretter forbindelse.
gtk-no-agents-yet = Ingen agent har bedt om at bruge din mail endnu.
gtk-nothing-yet = Intet endnu.

## Preferences

gtk-preferences = Indstillinger
gtk-notify-subtitle = Kun mens Inbox Classic er i baggrunden

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Mailprogram
gtk-desktop-comment = Læs og skriv e-mail: et hurtigt og enkelt mailprogram
gtk-desktop-keywords = mail;e-mail;post;indbakke;meddelelse;
gtk-metainfo-summary = Et hurtigt og enkelt mailprogram
gtk-metainfo-description = Inbox Classic er et klassisk mailprogram med mapper til venstre, meddelelsesliste øverst og læserude nedenunder. Det understøtter IMAP- og SMTP-konti samt login på Outlook.com og Microsoft 365 via browseren.
gtk-metainfo-feature-sanitized = Meddelelser renses for scripts og andet aktivt indhold. Billeder fra internettet hentes kun med din tilladelse
gtk-metainfo-feature-search = Søg i emner, afsendere, modtagere, navne på vedhæftede filer og meddelelsestekst med søgeoperatorer som i Gmail
gtk-metainfo-feature-replies = Citerede tidligere meddelelser foldes sammen i svar
gtk-metainfo-feature-offline = Hentede meddelelser kan læses uden internetforbindelse. Adgangskoder gemmes i din nøglering
