# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic fortsetter å se etter ny e-post i bakgrunnen. Klikk på ikonet for å åpne programmet. For å avslutte høyreklikker du på ikonet og bruker menyen.
# review: new
win-default-app-not-installed = Denne kopien av Inbox Classic ble ikke installert, så Windows viser den ikke som et e-postprogram. Installer den for å kunne velge den.
# review: new
win-default-app-settings = Windows åpner innstillingene for standardapper. Velg Inbox Classic for å åpne MAILTO-lenker.
# review: new
win-no-unread = Ingen uleste meldinger
# review: new
win-unread-messages = { $count ->
    [one] { $count } ulest melding
   *[other] { $count } uleste meldinger
}
# review: new
win-print-failed = Meldingen kunne ikke skrives ut.
# review: new
win-print-title-of = Skriv ut - { $subject }
# review: new
win-no-bodies = Meldingsinnhold kan ikke vises.
# review: new
win-webview-failed = Kunne ikke opprette WebView2.
# review: new
win-webview-missing = WebView2-kjøretiden er ikke tilgjengelig.
# review: new
win-list-loading = Laster inn...

## Buttons and words used in many windows

# review: new
win-delete-button = &Slett
# review: new
win-find-label = &Finn:
# review: new
win-save-as-button = Lagre &som...
# review: new
win-too-many-files = For mange filer på en gang: velg færre.

## The Outbox


## The compose window

# review: new
win-editor-failed = Meldinger kan ikke skrives.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+klikk for å åpne)
# review: new
win-format-bold = Fet ({ $ctrl }+B)
# review: new
win-format-italic = Kursiv ({ $ctrl }+I)
# review: new
win-format-underline = Understreking ({ $ctrl }+U)
# review: new
win-format-link = Hyperkobling ({ $ctrl }+K)
# review: new
win-show-cc = &Kopi
# review: new
win-show-bcc = &Blindkopi
# review: new
win-signature-title = Signatur: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Ingen treff for «{ $words }» i alle mapper
    [one] { $count } treff for «{ $words }» i alle mapper
   *[other] { $count } treff for «{ $words }» i alle mapper
}
# review: new
win-search-found-in = { $count ->
    [0] Ingen treff for «{ $words }» i { $folder }
    [one] { $count } treff for «{ $words }» i { $folder }
   *[other] { $count } treff for «{ $words }» i { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] indekserer fortsatt teksten i { $count } melding
   *[other] indekserer fortsatt teksten i { $count } meldinger
}
# review: new
win-no-match-indexing = { $count ->
    [one] Teksten i { $count } melding indekseres fortsatt, så flere treff kan dukke opp snart.
   *[other] Teksten i { $count } meldinger indekseres fortsatt, så flere treff kan dukke opp snart.
}
# review: new
win-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
# review: new
win-click-to-retry = Klikk her for å prøve igjen.
# review: new
win-save-attachments = &Lagre vedlegg...
# review: new
win-files-not-saved = { $failed } av de { $count } filene kunne ikke lagres.
# review: new
win-new-folder-in-highlighted = Den nye mappen opprettes inne i den valgte mappen.
# review: new
win-delete-folder-ask = Vil du slette mappen «{ $folder }» med meldingene og mappene i den? Den slettes også på serveren.
# review: new
win-rename = &Gi nytt navn...
# review: new
win-messages-not-saved = Meldingene kunne ikke lagres.
# review: new
win-messages-not-forwarded = Meldingene kunne ikke videresendes.

## Accounts

# review: new
win-sign-in-google = Logg på med Google
# review: new
win-sign-in-microsoft = Logg på med Microsoft
# review: new
win-next = &Neste >
# review: new
win-your-account = kontoen din
# review: new
win-browser-sign-in = (pålogging i nettleser)
# review: new
win-add = &Legg til...
# review: new
win-properties-button = &Egenskaper...
# review: new
win-signature-button = Si&gnatur...
# review: new
win-sign-in-apps-button = &Påloggingsapper...

## AI agents

# review: new
win-dont-allow = &Ikke tillat
# review: new
win-col-address = Adresse
# review: new
win-never-written-to = Aldri skrevet til
# review: new
win-book-find-label = Skriv inn et navn eller en e-postadresse:
# review: new
win-send = &Send
# review: new
win-dont-send = &Ikke send
# review: new
win-unsubscribe = &Meld av
# review: new
win-dont-unsubscribe = &Ikke meld av
# review: new
win-forget-program-ask = Vil du fjerne dette programmet, tillatelsene og aktivitetsloggen til agentene? Du blir spurt om tillatelse igjen neste gang det kobler til.
# review: new
win-clear-log-ask = Vil du tømme aktivitetsloggen til agentene? Dette angrer ikke endringer som agentene har gjort.
# review: new
win-agent-programs = &Programmer der agenter har bedt om tilgang til e-posten din:
# review: new
win-change = &Endre...
# review: new
win-what-agents-did = Agent&aktivitet:
# review: new
win-how-to-connect = Slik kobler du til en agent

## Sign-in apps

# review: new
win-built-in = (innebygd)
# review: new
win-edit = &Rediger...

## Options

# review: new
win-folders-hide = Skjul mappelisten
# review: new
win-folders-pin = Hold mappelisten ved siden av meldingene
# review: new
win-folders-show = Vis mappene

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Start Inbox Classic
# review: new
win-installer-welcome-new =
    Dette installerer Inbox Classic { $version }, et e-postprogram.

    Du trenger ikke administratorrettigheter, programmet installeres bare for kontoen din.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } er allerede installert. Dette installerer programmet på nytt.

    Kontoene og e-posten din beholdes.
# review: new
win-installer-welcome-update =
    Dette oppdaterer Inbox Classic { $installed } til { $version }.

    Hvis programmet kjører, lukkes det først. Kontoene og e-posten din beholdes.
# review: new
win-installer-older-ask = Inbox Classic { $installed } er installert, og den er nyere enn { $version }. Vil du installere den eldre versjonen likevel?
# review: new
win-installer-still-running = Inbox Classic kjører fortsatt. Lukk programmet og prøv igjen.
# review: new
win-installer-remove-mail-ask = Vil du også fjerne kontoene og e-posten som Inbox Classic har på denne datamaskinen? E-posten på serverne blir liggende.
