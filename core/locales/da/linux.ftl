# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Indstillinger, Afslut).

## The main window

# review: new
gtk-search-looks-in = Søgningen i { $place } omfatter emner, afsendere, modtagere, navne på vedhæftede filer og meddelelsestekst. Kontrollér stavningen, eller prøv med færre ord.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Teksten i 1 meddelelse indekseres stadig. Der kan snart dukke flere resultater op.
   *[other] Teksten i { $count } meddelelser indekseres stadig. Der kan snart dukke flere resultater op.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Ingen resultater
    [one] 1 resultat
   *[other] { $count } resultater
} for »{ $words }« i alle mapper
# review: new
gtk-search-results-in = { $count ->
    [0] Ingen resultater
    [one] 1 resultat
   *[other] { $count } resultater
} for »{ $words }« i { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] indekserer stadig teksten i 1 meddelelse
   *[other] indekserer stadig teksten i { $count } meddelelser
}
# review: new
gtk-list-loading = Indlæser...
# review: new
gtk-menu-rename = Omdøb...
# review: new
gtk-import-one-question = Vil du importere meddelelsen { $file } til { $folder }?
# review: new
gtk-files-not-saved = { $failed } af de { $total } filer kunne ikke gemmes.
# review: new
gtk-unsubscribe-one-click =
    Vil du forlade denne mailingliste?

    Inbox Classic sender en afmeldingsanmodning til { $target }. Der åbnes ingen webside, og der sendes ingen e-mail.
# review: new
gtk-unsubscribe-mail =
    Vil du forlade denne mailingliste?

    Send en e-mail til { $target } for at afmelde. Inbox Classic gør den klar til dig. Send meddelelsen for at bekræfte.
# review: new
gtk-unsubscribe-web =
    Vil du forlade denne mailingliste?

    Mailinglistens afmeldingsside åbnes i din browser ({ $target }).
# review: new
gtk-unsubscribe-failed = Kunne ikke afmelde: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Skriv fra en bestemt konto
# review: new
gtk-toolbar-send-recv-menu = Send og modtag mail for en bestemt konto
# review: new
gtk-main-menu = Hovedmenu
# review: new
gtk-folder-list = Mappeliste
# review: new
gtk-quit = Afslut

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Den nye mappe placeres øverst i { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Ingen ulæste meddelelser
    [one] 1 ulæst meddelelse
   *[other] { $count } ulæste meddelelser
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Der er ingen meddelelser, der venter på at blive sendt.
# review: new
gtk-outbox-row = Til: { $to }  ·  I kø { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic bliver ved med at søge efter ny mail i baggrunden. Brug programmets ikon i toppanelet til at åbne eller afslutte programmet.
# review: new
gtk-sign-in-again-ask =
    Login til { $account } blev afvist, eller sessionen er udløbet.

    Vil du logge på igen i browseren?
# review: new
gtk-default-app-not-installed = Denne kopi af Inbox Classic er ikke installeret, så systemet viser den ikke som mailprogram. Installer den for at kunne vælge den.
# review: new
gtk-default-app-now = Inbox Classic er nu dit standardmailprogram: e-maillinks åbner en ny meddelelse her.
# review: new
gtk-default-app-failed = Inbox Classic kunne ikke gøres til standardmailprogram.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Dato:
# review: new
gtk-reader-files = Vedhæftede filer
# review: new
gtk-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
# review: new
gtk-pictures-blocked = Nogle billeder er blokeret for at forhindre afsenderen i at identificere din computer.
# review: new
gtk-download-pictures = Hent billeder
# review: new
gtk-save-attachments-menu = Gem vedhæftede filer...

## The compose window

# review: new
gtk-format-bold = Fed (Ctrl+B)
# review: new
gtk-format-italic = Kursiv (Ctrl+I)
# review: new
gtk-format-underline = Understreget (Ctrl+U)
# review: new
gtk-format-hyperlink = Link (Ctrl+K)
# review: new
gtk-font = Skrifttype
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Gem (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+klik for at åbne)

## Accounts

# review: new
gtk-plain-warning =
    Uden kryptering kan alle, der opsnapper din netværkstrafik, læse din adgangskode og dine meddelelser. Brug kun denne forbindelse med en server på din egen computer eller dit lokale netværk.

    Vil du fortsætte?
# review: new
gtk-account-name-title = Kontonavn
# review: new
gtk-display-name-title = Vist navn
# review: new
gtk-turned-off-why = Muligheden »{ $button }« er slået fra på denne computer. { $reason }
# review: new
gtk-turned-off-why-long =
    Muligheden »{ $button }« er slået fra på denne computer.

    { $reason }
# review: new
gtk-next = Næste >
# review: new
gtk-provider-sign-in = Log på { $address } på webstedet for { $provider }. Din adgangskode deles ikke med Inbox Classic. Du kan også bruge en appadgangskode, som du opretter i kontoens sikkerhedsindstillinger.
# review: new
gtk-provider-sign-in-apps = Log på { $address } på webstedet for { $provider } med en af dine login-apps (Flere loginmuligheder). Du kan også bruge en appadgangskode, som du opretter i kontoens sikkerhedsindstillinger.
# review: new
gtk-accounts-add = Tilføj...
# review: new
gtk-accounts-properties = Egenskaber...
# review: new
gtk-accounts-signature = Signatur...
# review: new
gtk-accounts-sign-in-apps = Login-apps...

## Sign-in apps

# review: new
gtk-app-server = { $kind }-server
# review: new
gtk-app-port = { $kind }-port
# review: new
gtk-app-security = { $kind }-sikkerhed
# review: new
gtk-issuer-found =
    Loginside: { $page }
    Token-endpoint: { $endpoint }
# review: new
gtk-client-id = Klient-id
# review: new
gtk-client-secret = Klienthemmelighed
# review: new
gtk-scopes = Tilladelser (scopes)
# review: new
gtk-redirect-uri = Omdirigerings-URI
# review: new
gtk-issuer-usable =
    Udstederen kan bruges.

    { $found }
# review: new
gtk-app-built-in = { $app } er indbygget. Du kan kun ændre, om den tilbydes til nye konti. { $reason }
# review: new
gtk-built-in = { $app } (indbygget)
# review: new
gtk-offered-for-new = Tilbydes til nye konti
# review: new
gtk-edit-button = Rediger...
# review: new
gtk-remove-app-ask = Vil du fjerne login-appen { $app } og dens gemte klienthemmelighed?
# review: new
gtk-sign-in-apps-intro = Login-apps lader konti logge på via browseren. En app, der er slået fra, tilbydes ikke til nye konti; de konti, der allerede bruger den, virker fortsat.

## AI agents

# review: new
gtk-agent-it-may = Tilladte handlinger
# review: new
gtk-agent-accounts = Tilladte konti
# review: new
gtk-never-used = Aldrig brugt
# review: new
gtk-last-used = Senest brugt { $date }
# review: new
gtk-forget-program = Vil du fjerne dette program?
# review: new
gtk-forget-program-detail = Programmets tilladelser og dets agenters aktivitetshistorik slettes. Du bliver spurgt om tilladelse igen, næste gang det opretter forbindelse.
# review: new
gtk-no-agents-yet = Ingen agent har bedt om at bruge din mail endnu.
# review: new
gtk-nothing-yet = Intet endnu.

## Preferences

# review: new
gtk-preferences = Indstillinger
# review: changed
gtk-notify-subtitle = Kun mens Inbox Classic er i baggrunden

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Mailprogram
# review: new
gtk-desktop-comment = Læs og skriv e-mail: et hurtigt og enkelt mailprogram
# review: new
gtk-desktop-keywords = mail;e-mail;post;indbakke;meddelelse;
# review: new
gtk-metainfo-summary = Et hurtigt og enkelt mailprogram
# review: new
gtk-metainfo-description = Inbox Classic læser og skriver e-mail med mapperne til venstre, meddelelserne øverst og meddelelsen nedenunder, som mailprogrammer plejede at gøre. Det virker med enhver IMAP- og SMTP-konto og logger på Outlook.com og Microsoft 365 via browseren.
# review: new
gtk-metainfo-feature-sanitized = Alle meddelelser vises renset, uden scripts, og billeder fra internettet kun, når du tillader det
# review: new
gtk-metainfo-feature-search = En søgning, der finder ord i emnet, afsendere og modtagere, filnavne og teksten, med Gmails søgeoperatorer
# review: new
gtk-metainfo-feature-replies = Svar folder de tidligere meddelelser, de citerer, sammen
# review: new
gtk-metainfo-feature-offline = Mailen kan læses offline; adgangskoder gemmes i din nøglering
