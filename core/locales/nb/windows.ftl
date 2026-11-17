# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic fortsetter å se etter ny e-post i bakgrunnen. Klikk på ikonet i systemstatusfeltet for å åpne programmet. Høyreklikk på ikonet og velg Avslutt for å avslutte.
win-default-app-not-installed = Denne kopien av Inbox Classic er ikke installert. Installer programmet for å kunne velge det som standard e-postprogram i Windows.
win-default-app-settings = Windows åpner innstillingene for standardapper. Velg Inbox Classic for å åpne MAILTO-lenker.
win-no-unread = Ingen uleste meldinger
win-unread-messages = { $count ->
    [one] { $count } ulest melding
   *[other] { $count } uleste meldinger
}
win-print-failed = Meldingen kunne ikke skrives ut.
win-print-title-of = Skriv ut - { $subject }
win-no-bodies = Meldingsinnhold kan ikke vises.
win-webview-failed = Kunne ikke starte meldingsvisningen (WebView2).
win-webview-missing = Komponenten WebView2 som viser meldinger, er ikke tilgjengelig.
win-list-loading = Laster inn...

## Buttons and words used in many windows

win-delete-button = Sle&tt
win-find-label = F&inn:
win-save-as-button = La&gre som...
win-too-many-files = For mange filer på en gang: velg færre.

## The Outbox


## The compose window

win-editor-failed = Kunne ikke starte meldingsredigeringen.
win-ctrl-click-to-open = ({ $ctrl }+klikk for å åpne)
win-format-bold = Fet ({ $ctrl }+B)
win-format-italic = Kursiv ({ $ctrl }+I)
win-format-underline = Understreking ({ $ctrl }+U)
win-format-link = Hyperkobling ({ $ctrl }+K)
win-show-cc = &Kopi
win-show-bcc = &Blindkopi
win-signature-title = Signatur: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Ingen treff for «{ $words }» i alle mapper
    [one] { $count } treff for «{ $words }» i alle mapper
   *[other] { $count } treff for «{ $words }» i alle mapper
}
win-search-found-in = { $count ->
    [0] Ingen treff for «{ $words }» i { $folder }
    [one] { $count } treff for «{ $words }» i { $folder }
   *[other] { $count } treff for «{ $words }» i { $folder }
}
win-search-indexing = { $count ->
    [one] indekserer fortsatt teksten i { $count } melding
   *[other] indekserer fortsatt teksten i { $count } meldinger
}
win-no-match-indexing = { $count ->
    [one] Teksten i { $count } melding indekseres fortsatt, så flere treff kan dukke opp snart.
   *[other] Teksten i { $count } meldinger indekseres fortsatt, så flere treff kan dukke opp snart.
}
win-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
win-click-to-retry = Klikk her for å prøve igjen.
win-save-attachments = &Lagre vedlegg...
win-files-not-saved = Kunne ikke lagre { $failed } av totalt { $count } filer.
win-new-folder-in-highlighted = Den nye mappen opprettes inne i den valgte mappen.
win-delete-folder-ask = Vil du slette mappen «{ $folder }» med meldingene og mappene i den? Den slettes også på serveren.
win-rename = &Gi nytt navn...
win-messages-not-saved = Meldingene kunne ikke lagres.
win-messages-not-forwarded = Meldingene kunne ikke videresendes.

## Accounts

win-sign-in-google = Logg på med Google
win-sign-in-microsoft = Logg på med Microsoft
win-next = &Neste >
win-your-account = kontoen din
win-browser-sign-in = (pålogging i nettleser)
win-add = &Legg til...
win-properties-button = &Egenskaper...
win-signature-button = Si&gnatur...
win-sign-in-apps-button = &Påloggingsapper...

## AI agents

win-dont-allow = &Ikke tillat
win-col-address = Adresse
win-never-written-to = Aldri skrevet til
win-book-find-label = Skriv inn et navn eller en e-postadresse:
win-send = &Send
win-dont-send = &Ikke send
win-forget-program-ask = Vil du fjerne dette programmet, tillatelsene og aktivitetsloggen til agentene? Du blir spurt om tillatelse igjen neste gang det kobler til.
win-clear-log-ask = Vil du tømme aktivitetsloggen til agentene? Dette angrer ikke endringer som agentene har gjort.
win-agent-programs = &Programmer der agenter har bedt om tilgang til e-posten din:
win-change = &Endre...
win-what-agents-did = Age&ntaktivitet:
win-how-to-connect = Slik kobler du til en agent

## Sign-in apps

win-built-in = (innebygd)
win-edit = &Rediger...

## Options

win-options-language-label = V&is Inbox Classic på:
win-options-restart-note = Start Inbox Classic på nytt for å bytte språk.
win-options-notify = &Varsle meg når det kommer ny e-post
win-restart-ask = Inbox Classic vises på { $language } når programmet startes på nytt. Vil du starte på nytt nå?
win-folders-hide = Skjul mappelisten
win-folders-pin = Hold mappelisten ved siden av meldingene
win-folders-show = Vis mappene

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Start Inbox Classic
win-installer-welcome-new =
    Dette installerer e-postprogrammet Inbox Classic { $version }.

    Du trenger ikke administratorrettigheter. Programmet installeres bare for din Windows-bruker.
win-installer-welcome-same =
    Inbox Classic { $version } er allerede installert. Dette installerer programmet på nytt.

    Kontoene og e-posten din beholdes.
win-installer-welcome-update =
    Dette oppdaterer Inbox Classic { $installed } til { $version }.

    Hvis programmet kjører, lukkes det først. Kontoene og e-posten din beholdes.
win-installer-older-ask = Inbox Classic { $installed } er allerede installert. Dette er en nyere versjon enn { $version }. Vil du installere den eldre versjonen likevel?
win-installer-still-running = Inbox Classic kjører fortsatt. Lukk programmet og prøv igjen.
win-installer-remove-mail-ask = Vil du også fjerne kontoene og de lokale kopiene av e-posten fra denne datamaskinen? E-posten blir liggende på serverne.
