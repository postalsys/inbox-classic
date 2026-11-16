# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Brukervalg, Avslutt).

## The main window

# review: new
gtk-search-looks-in = Søket i { $place } omfatter emne, avsendere, mottakere, navn på vedlegg og meldingstekst. Kontroller stavemåten, eller prøv med færre ord.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Teksten i { $count } melding indekseres fortsatt. Flere treff kan dukke opp snart.
   *[other] Teksten i { $count } meldinger indekseres fortsatt. Flere treff kan dukke opp snart.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Ingen treff
    [one] { $count } treff
   *[other] { $count } treff
} for «{ $words }» i alle mapper
# review: new
gtk-search-results-in = { $count ->
    [0] Ingen treff
    [one] { $count } treff
   *[other] { $count } treff
} for «{ $words }» i { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] indekserer fortsatt teksten i { $count } melding
   *[other] indekserer fortsatt teksten i { $count } meldinger
}
# review: new
gtk-list-loading = Laster inn...
# review: new
gtk-menu-rename = Gi nytt navn...
# review: new
gtk-import-one-question = Vil du importere meldingen { $file } til { $folder }?
# review: new
gtk-files-not-saved = { $failed } av de { $total } filene kunne ikke lagres.
# review: new
gtk-unsubscribe-one-click =
    Vil du melde deg av denne e-postlisten?

    Inbox Classic sender en forespørsel om avmelding til { $target }. Ingen nettside åpnes, og ingen e-post sendes.
# review: new
gtk-unsubscribe-mail =
    Vil du melde deg av denne e-postlisten?

    For å melde deg av sender du en e-post til { $target }. Inbox Classic gjør den klar for deg. Send meldingen for å bekrefte.
# review: new
gtk-unsubscribe-web =
    Vil du melde deg av denne e-postlisten?

    Avmeldingssiden til e-postlisten åpnes i nettleseren ({ $target }).
# review: new
gtk-unsubscribe-failed = Kunne ikke melde av: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Skriv fra en bestemt konto
# review: new
gtk-toolbar-send-recv-menu = Send og motta e-post for en bestemt konto
# review: new
gtk-main-menu = Hovedmeny
# review: new
gtk-folder-list = Mappeliste
# review: new
gtk-quit = Avslutt

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Den nye mappen legges øverst i { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Ingen uleste meldinger
    [one] { $count } ulest melding
   *[other] { $count } uleste meldinger
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Ingen meldinger venter på å bli sendt.
# review: new
gtk-outbox-row = Til: { $to }  ·  I kø { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic fortsetter å se etter ny e-post i bakgrunnen. Bruk ikonet i topplinjen for å åpne eller avslutte appen.
# review: new
gtk-sign-in-again-ask =
    Påloggingen til { $account } ble avvist, eller økten er utløpt.

    Vil du logge på igjen i nettleseren?
# review: new
gtk-default-app-not-installed = Denne kopien av Inbox Classic ble ikke installert, så systemet viser den ikke som et e-postprogram. Installer den for å kunne velge den.
# review: new
gtk-default-app-now = Inbox Classic er nå standard e-postprogram: e-postlenker åpner en ny melding her.
# review: new
gtk-default-app-failed = Inbox Classic kunne ikke gjøres til standard e-postprogram.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Dato:
# review: new
gtk-reader-files = Vedlegg i meldingen
# review: new
gtk-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
# review: new
gtk-pictures-blocked = Noen bilder er blokkert for å hindre at avsenderen kan identifisere datamaskinen din.
# review: new
gtk-download-pictures = Last ned bilder
# review: new
gtk-save-attachments-menu = Lagre vedlegg...

## The compose window

# review: new
gtk-format-bold = Fet (Ctrl+B)
# review: new
gtk-format-italic = Kursiv (Ctrl+I)
# review: new
gtk-format-underline = Understreking (Ctrl+U)
# review: new
gtk-format-hyperlink = Hyperkobling (Ctrl+K)
# review: new
gtk-font = Skrift
# review: new
gtk-show-cc = _Kopi
# review: new
gtk-show-bcc = _Blindkopi
# review: new
gtk-save-tip = Lagre (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+klikk for å åpne)

## Accounts

# review: new
gtk-plain-warning =
    Uten kryptering kan alle som fanger opp nettverkstrafikken din, lese passordet og meldingene dine. Bruk bare denne tilkoblingen med en server på din egen datamaskin eller ditt lokale nettverk.

    Vil du fortsette?
# review: new
gtk-account-name-title = Kontonavn
# review: new
gtk-display-name-title = Visningsnavn
# review: new
gtk-turned-off-why = Valget «{ $button }» er slått av på denne datamaskinen. { $reason }
# review: new
gtk-turned-off-why-long =
    Valget «{ $button }» er slått av på denne datamaskinen.

    { $reason }
# review: new
gtk-next = Neste >
# review: new
gtk-provider-sign-in = Logg på { $address } på nettstedet til { $provider }. Passordet ditt deles ikke med Inbox Classic. Du kan også bruke et app-passord som er opprettet i sikkerhetsinnstillingene for kontoen.
# review: new
gtk-provider-sign-in-apps = Logg på { $address } på nettstedet til { $provider } med en av påloggingsappene dine (Flere påloggingsvalg). Du kan også bruke et app-passord som er opprettet i sikkerhetsinnstillingene for kontoen.
# review: new
gtk-accounts-add = Legg til...
# review: new
gtk-accounts-properties = Egenskaper...
# review: new
gtk-accounts-signature = Signatur...
# review: new
gtk-accounts-sign-in-apps = Påloggingsapper...

## Sign-in apps

# review: new
gtk-app-server = { $kind }-server
# review: new
gtk-app-port = { $kind }-port
# review: new
gtk-app-security = { $kind }-sikkerhet
# review: new
gtk-issuer-found =
    Påloggingsside: { $page }
    Tokenendepunkt: { $endpoint }
# review: new
gtk-client-id = Klient-ID
# review: new
gtk-client-secret = Klienthemmelighet
# review: new
gtk-scopes = Tillatelser (scopes)
# review: new
gtk-redirect-uri = Omdirigerings-URI
# review: new
gtk-issuer-usable =
    Utstederen kan brukes.

    { $found }
# review: new
gtk-app-built-in = { $app } er innebygd. Du kan bare endre om den tilbys for nye kontoer. { $reason }
# review: new
gtk-built-in = { $app } (innebygd)
# review: new
gtk-offered-for-new = Tilbys for nye kontoer
# review: new
gtk-edit-button = Rediger...
# review: new
gtk-remove-app-ask = Vil du fjerne påloggingsappen { $app } og den lagrede klienthemmeligheten?
# review: new
gtk-sign-in-apps-intro = Med påloggingsapper kan kontoer logge på gjennom nettleseren. En app som er slått av, tilbys ikke for nye kontoer; kontoene som allerede bruker den, fortsetter å virke.

## AI agents

# review: new
gtk-agent-it-may = Tillatte handlinger
# review: new
gtk-agent-accounts = Tillatte kontoer
# review: new
gtk-never-used = Aldri brukt
# review: new
gtk-last-used = Sist brukt { $date }
# review: new
gtk-forget-program = Vil du fjerne dette programmet?
# review: new
gtk-forget-program-detail = Tillatelsene til programmet og aktivitetsloggen til agentene slettes. Du blir spurt om tillatelse igjen neste gang det kobler til.
# review: new
gtk-no-agents-yet = Ingen agent har bedt om å bruke e-posten din ennå.
# review: new
gtk-nothing-yet = Ingenting ennå.

## Preferences

# review: new
gtk-preferences = Brukervalg
# review: new
gtk-language = Språk
# review: new
gtk-language-subtitle = Språket i appen og hjelpen
# review: new
gtk-new-mail-group = Ny e-post
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Varsle om ny e-post
# review: new
gtk-notify-subtitle = Et varsel når nye meldinger kommer mens vinduet er i bakgrunnen
# review: new
gtk-restart-to-change = Inbox Classic startes på nytt for å bytte språk.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = E-postklient
# review: new
gtk-desktop-comment = Les og skriv e-post: et raskt og enkelt e-postprogram
# review: new
gtk-desktop-keywords = epost;e-post;post;innboks;melding;
# review: new
gtk-metainfo-summary = Et raskt og enkelt e-postprogram
# review: new
gtk-metainfo-description = Inbox Classic leser og skriver e-post med mappene til venstre, meldingene øverst og meldingen nedenfor, slik e-postprogrammer pleide å gjøre. Det fungerer med alle IMAP- og SMTP-kontoer, og logger på Outlook.com og Microsoft 365 gjennom nettleseren.
# review: new
gtk-metainfo-feature-sanitized = Hver melding vises renset, uten skript, og bilder fra internett bare når du tillater det
# review: new
gtk-metainfo-feature-search = Et søk som finner ord i emnet, personene, filnavnene og teksten, med søkeoperatorene til Gmail
# review: new
gtk-metainfo-feature-replies = Svar folder bort de tidligere meldingene de siterer
# review: new
gtk-metainfo-feature-offline = E-posten kan leses uten nett; passord oppbevares i nøkkelringen din
