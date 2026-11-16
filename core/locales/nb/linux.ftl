# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Brukervalg, Avslutt).

## The main window

gtk-search-looks-in = Søket i { $place } omfatter emne, avsendere, mottakere, navn på vedlegg og meldingstekst. Kontroller stavemåten, eller prøv med færre ord.
gtk-search-still-indexing = { $count ->
    [one] Teksten i { $count } melding indekseres fortsatt. Flere treff kan dukke opp snart.
   *[other] Teksten i { $count } meldinger indekseres fortsatt. Flere treff kan dukke opp snart.
}
gtk-search-results-everywhere = { $count ->
    [0] Ingen treff
    [one] { $count } treff
   *[other] { $count } treff
} for «{ $words }» i alle mapper
gtk-search-results-in = { $count ->
    [0] Ingen treff
    [one] { $count } treff
   *[other] { $count } treff
} for «{ $words }» i { $place }
gtk-search-indexing = { $count ->
    [one] indekserer fortsatt teksten i { $count } melding
   *[other] indekserer fortsatt teksten i { $count } meldinger
}
# review: new
gtk-list-loading = Laster inn...
gtk-menu-rename = Gi nytt navn...
gtk-import-one-question = Vil du importere meldingen { $file } til { $folder }?
gtk-files-not-saved = Kunne ikke lagre { $failed } av totalt { $total } filer.
gtk-unsubscribe-one-click =
    Vil du melde deg av denne e-postlisten?

    Inbox Classic sender en forespørsel om avmelding til { $target }. Ingen nettside åpnes, og ingen e-post sendes.
gtk-unsubscribe-mail =
    Vil du melde deg av denne e-postlisten?

    For å melde deg av sender du en e-post til { $target }. Inbox Classic gjør den klar for deg. Send meldingen for å bekrefte.
gtk-unsubscribe-web =
    Vil du melde deg av denne e-postlisten?

    Avmeldingssiden til e-postlisten åpnes i nettleseren ({ $target }).
gtk-unsubscribe-failed = Avmeldingen mislyktes: { $problem }
gtk-toolbar-create-mail-menu = Skriv fra en bestemt konto
gtk-toolbar-send-recv-menu = Send og motta e-post for en bestemt konto
gtk-main-menu = Hovedmeny
gtk-folder-list = Mappeliste
gtk-quit = Avslutt

## The Move and Copy window

gtk-new-folder-at-top-of = Den nye mappen opprettes på øverste nivå i kontoen { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Ingen uleste meldinger
    [one] { $count } ulest melding
   *[other] { $count } uleste meldinger
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Ingen meldinger venter på å bli sendt.
gtk-outbox-row = Til: { $to }  ·  Lagt i kø: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic fortsetter å se etter ny e-post i bakgrunnen. Bruk ikonet i topplinjen for å åpne eller avslutte appen.
gtk-sign-in-again-ask =
    Påloggingen til { $account } ble avvist, eller økten er utløpt.

    Vil du logge på igjen i nettleseren?
gtk-default-app-not-installed = Denne kopien av Inbox Classic er ikke installert. Installer programmet for å kunne velge det som standard e-postprogram.
gtk-default-app-now = Inbox Classic er nå standard e-postprogram: e-postlenker åpner en ny melding her.
gtk-default-app-failed = Inbox Classic kunne ikke gjøres til standard e-postprogram.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Dato:
gtk-reader-files = Vedlegg i meldingen
gtk-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
gtk-pictures-blocked = Noen bilder er blokkert for å hindre at avsenderen sporer deg.
gtk-download-pictures = Last ned bilder
gtk-save-attachments-menu = Lagre vedlegg...

## The compose window

gtk-format-bold = Fet (Ctrl+B)
gtk-format-italic = Kursiv (Ctrl+I)
gtk-format-underline = Understreking (Ctrl+U)
gtk-format-hyperlink = Hyperkobling (Ctrl+K)
gtk-font = Skrift
gtk-show-cc = _Kopi
gtk-show-bcc = _Blindkopi
gtk-save-tip = Lagre (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+klikk for å åpne)

## Accounts

gtk-plain-warning =
    Uten kryptering kan alle som fanger opp nettverkstrafikken din, lese passordet og meldingene dine. Bruk bare denne tilkoblingen med en server på din egen datamaskin eller ditt lokale nettverk.

    Vil du fortsette?
gtk-account-name-title = Kontonavn
gtk-display-name-title = Visningsnavn
gtk-turned-off-why = Valget «{ $button }» er slått av på denne datamaskinen. { $reason }
gtk-turned-off-why-long =
    Valget «{ $button }» er slått av på denne datamaskinen.

    { $reason }
gtk-next = Neste >
gtk-provider-sign-in = { $provider }: Logg på kontoen { $address } på leverandørens nettsted. Passordet ditt deles ikke med Inbox Classic. Du kan også bruke et app-passord som er opprettet i sikkerhetsinnstillingene for kontoen.
gtk-provider-sign-in-apps = { $provider }: Bruk en av påloggingsappene dine (Flere påloggingsvalg) til å logge på kontoen { $address } på leverandørens nettsted. Du kan også bruke et app-passord som er opprettet i sikkerhetsinnstillingene for kontoen.
gtk-accounts-add = Legg til...
gtk-accounts-properties = Egenskaper...
gtk-accounts-signature = Signatur...
gtk-accounts-sign-in-apps = Påloggingsapper...

## Sign-in apps

gtk-app-server = { $kind }-server
gtk-app-port = { $kind }-port
gtk-app-security = { $kind }-sikkerhet
gtk-issuer-found =
    Påloggingsside: { $page }
    Tokenendepunkt: { $endpoint }
gtk-client-id = Klient-ID
gtk-client-secret = Klienthemmelighet
gtk-scopes = Tillatelser (scopes)
gtk-redirect-uri = Omdirigerings-URI
gtk-issuer-usable =
    Utstederen kan brukes.

    { $found }
gtk-app-built-in = { $app } er innebygd. Du kan bare endre om den tilbys for nye kontoer. { $reason }
gtk-built-in = { $app } (innebygd)
gtk-offered-for-new = Tilbys for nye kontoer
gtk-edit-button = Rediger...
gtk-remove-app-ask = Vil du fjerne påloggingsappen { $app } og den lagrede klienthemmeligheten?
gtk-sign-in-apps-intro = Med påloggingsapper kan kontoer logge på gjennom nettleseren. En app som er slått av, tilbys ikke for nye kontoer; kontoene som allerede bruker den, fortsetter å virke.

## AI agents

gtk-agent-it-may = Tillatte handlinger
gtk-agent-accounts = Tillatte kontoer
gtk-never-used = Aldri brukt
gtk-last-used = Sist brukt { $date }
gtk-forget-program = Vil du fjerne dette programmet?
gtk-forget-program-detail = Tillatelsene til programmet og aktivitetsloggen til agentene slettes. Du blir spurt om tillatelse igjen neste gang det kobler til.
gtk-no-agents-yet = Ingen agenter har bedt om tilgang til e-posten din ennå.
gtk-nothing-yet = Ingenting ennå.

## Preferences

gtk-preferences = Brukervalg
gtk-language = Språk
gtk-language-subtitle = Språket i appen og hjelpen
gtk-new-mail-group = Ny e-post
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
gtk-notify-new-mail = Varsle om ny e-post
gtk-notify-subtitle = Et varsel når nye meldinger kommer mens vinduet er i bakgrunnen
gtk-restart-to-change = Inbox Classic startes på nytt for å bytte språk.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = E-postklient
gtk-desktop-comment = Les og skriv e-post: et raskt og enkelt e-postprogram
gtk-desktop-keywords = epost;e-post;post;innboks;melding;
gtk-metainfo-summary = Et raskt og enkelt e-postprogram
gtk-metainfo-description = Inbox Classic er et e-postprogram med mappene til venstre, meldingslisten øverst og lesevinduet nedenfor. Det fungerer med alle IMAP- og SMTP-kontoer og lar deg logge på Outlook.com og Microsoft 365 gjennom nettleseren.
gtk-metainfo-feature-sanitized = Meldinger vises uten skript og annet usikkert innhold. Bilder fra internett lastes bare ned med din tillatelse
gtk-metainfo-feature-search = Søk i emne, avsendere, mottakere, vedleggsnavn og meldingstekst med søkeoperatorer som i Gmail
gtk-metainfo-feature-replies = Siterte meldinger foldes sammen i svar og kan utvides når du vil lese dem
gtk-metainfo-feature-offline = Les nedlastet e-post uten nett. Passord lagres i systemets nøkkelring
