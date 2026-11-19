# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic bliver ved med at søge efter ny mail i baggrunden. Klik på ikonet for at åbne programmet. Højreklik på ikonet, og brug dets menu for at afslutte.
win-default-app-not-installed = Inbox Classic skal installeres, før Windows kan tilbyde det som standardmailprogram.
win-default-app-settings = Windows åbner sine indstillinger for standardapps. Vælg Inbox Classic til at åbne MAILTO-links.
win-no-unread = Ingen ulæste meddelelser
win-unread-messages = { $count ->
    [one] 1 ulæst meddelelse
   *[other] { $count } ulæste meddelelser
}
win-print-failed = Meddelelsen kunne ikke udskrives.
win-print-title-of = Udskriv - { $subject }
win-no-bodies = Indholdet af meddelelser kan ikke vises.
win-webview-failed = WebView2 kunne ikke oprettes.
win-webview-missing = WebView2-runtime er ikke tilgængelig.
win-list-loading = Indlæser...

## Buttons and words used in many windows

win-delete-button = Sle&t
win-find-label = &Find:
win-save-as-button = Ge&m som...
win-too-many-files = For mange filer på én gang: vælg færre.

## The Outbox


## The compose window

win-editor-failed = Der kan ikke skrives meddelelser.
win-ctrl-click-to-open = ({ $ctrl }+klik for at åbne)
win-format-bold = Fed ({ $ctrl }+B)
win-format-italic = Kursiv ({ $ctrl }+I)
win-format-underline = Understreget ({ $ctrl }+U)
win-format-link = Link ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Signatur: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Ingen resultater for »{ $words }« i alle mapper
    [one] { $count } resultat for »{ $words }« i alle mapper
   *[other] { $count } resultater for »{ $words }« i alle mapper
}
win-search-found-in = { $count ->
    [0] Ingen resultater for »{ $words }« i { $folder }
    [one] { $count } resultat for »{ $words }« i { $folder }
   *[other] { $count } resultater for »{ $words }« i { $folder }
}
win-search-indexing = { $count ->
    [one] indekserer stadig teksten i { $count } meddelelse
   *[other] indekserer stadig teksten i { $count } meddelelser
}
win-no-match-indexing = { $count ->
    [one] Teksten i { $count } meddelelse indekseres stadig. Der kan derfor snart dukke flere resultater op.
   *[other] Teksten i { $count } meddelelser indekseres stadig. Der kan derfor snart dukke flere resultater op.
}
win-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
win-click-to-retry = Klik her for at prøve igen.
win-save-attachments = &Gem vedhæftede filer...
win-files-not-saved = { $count ->
    [one] Filen kunne ikke gemmes.
   *[other] { $failed } af de { $count } filer kunne ikke gemmes.
}
win-new-folder-in-highlighted = Den nye mappe oprettes i den markerede mappe.
win-delete-folder-ask = Vil du slette mappen »{ $folder }« med dens meddelelser og de mapper, den indeholder? Den slettes også på serveren.
win-rename = Om&døb...
win-messages-not-saved = Meddelelserne kunne ikke gemmes.
win-messages-not-forwarded = Meddelelserne kunne ikke videresendes.

## Accounts

win-sign-in-google = Log ind med Google
win-sign-in-microsoft = Log på med Microsoft
win-next = &Næste >
win-your-account = din konto
win-browser-sign-in = (login via browser)
win-add = &Tilføj...
win-properties-button = &Egenskaber...
win-signature-button = Si&gnatur...
win-sign-in-apps-button = Login-a&pps...

## AI agents

win-dont-allow = Tillad &ikke
win-col-address = Adresse
win-never-written-to = Aldrig skrevet til
win-book-find-label = Skriv et navn eller en e-mailadresse:
win-send = &Send
win-dont-send = Send &ikke
win-unsubscribe = &Afmeld
win-dont-unsubscribe = Afmeld &ikke
win-forget-program-ask = Vil du fjerne dette program fra listen, dets tilladelser og dets agenters aktivitetshistorik? Du bliver spurgt om tilladelse igen, næste gang det opretter forbindelse.
win-clear-log-ask = Vil du rydde agenternes aktivitetshistorik? Det fortryder ikke de ændringer, agenterne har foretaget.
win-agent-programs = &Programmer, hvis agenter har bedt om adgang til din mail:
win-change = &Rediger...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Fortryd ændringer &siden...
win-take-back = &Fortryd
win-what-agents-did = Agent&aktivitet:
win-agent-reads = Hvad der blev læst fra { $from } til { $to }:
win-agent-reads-hint = Marker en række med læsninger ovenfor for at se, hvad der blev læst.
win-how-to-connect = Sådan tilslutter du en agent

## Sign-in apps

win-built-in = (indbygget)
win-edit = &Rediger...

## Options

win-folders-hide = Skjul mappelisten
win-folders-pin = Fastgør mappelisten ved siden af meddelelserne
win-folders-show = Vis mapperne

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Start Inbox Classic
win-installer-welcome-new =
    Installer Inbox Classic { $version }, et mailprogram.

    Programmet installeres kun til din Windows-brugerkonto og kræver ingen administratorrettigheder.
win-installer-welcome-same =
    Inbox Classic { $version } er allerede installeret. Fortsæt for at installere programmet igen.

    Dine konti og din mail bevares.
win-installer-welcome-update =
    Opdater Inbox Classic fra version { $installed } til { $version }.

    Programmet lukkes først, hvis det kører. Dine konti og din mail bevares.
win-installer-older-ask = Inbox Classic { $installed } er installeret, og den er nyere end { $version }. Vil du installere den ældre version alligevel?
win-installer-still-running = Inbox Classic kører stadig. Luk programmet, og prøv igen.
win-installer-remove-mail-ask = Vil du også fjerne alle lokale data fra Inbox Classic, herunder konti, meddelelser i Udbakke, hentet mail, kontakter, nøgler og indstillinger? Mailen på serverne bevares. Gemte oplysninger i Windows Legitimationsstyring fjernes ikke.
