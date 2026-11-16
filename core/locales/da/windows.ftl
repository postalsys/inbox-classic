# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic bliver ved med at søge efter ny mail i baggrunden. Klik på ikonet for at åbne programmet. Højreklik på ikonet, og brug dets menu for at afslutte.
# review: new
win-default-app-not-installed = Denne kopi af Inbox Classic er ikke installeret, så Windows viser den ikke som mailprogram. Installer den for at kunne vælge den.
# review: new
win-default-app-settings = Windows åbner sine indstillinger for standardapps. Vælg Inbox Classic til at åbne MAILTO-links.
# review: new
win-no-unread = Ingen ulæste meddelelser
# review: new
win-unread-messages = { $count ->
    [one] 1 ulæst meddelelse
   *[other] { $count } ulæste meddelelser
}
# review: new
win-print-failed = Meddelelsen kunne ikke udskrives.
# review: new
win-print-title-of = Udskriv - { $subject }
# review: new
win-no-bodies = Meddelelsers indhold kan ikke vises.
# review: new
win-webview-failed = WebView2 kunne ikke oprettes.
# review: new
win-webview-missing = WebView2-runtime er ikke tilgængelig.
win-list-loading = Indlæser...

## Buttons and words used in many windows

# review: new
win-delete-button = &Slet
# review: new
win-find-label = &Find:
# review: new
win-save-as-button = Gem &som...
# review: new
win-too-many-files = For mange filer på én gang: vælg færre.

## The Outbox


## The compose window

# review: new
win-editor-failed = Der kan ikke skrives meddelelser.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+klik for at åbne)
# review: new
win-format-bold = Fed ({ $ctrl }+B)
# review: new
win-format-italic = Kursiv ({ $ctrl }+I)
# review: new
win-format-underline = Understreget ({ $ctrl }+U)
# review: new
win-format-link = Link ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Signatur: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Ingen resultater for »{ $words }« i alle mapper
    [one] { $count } resultat for »{ $words }« i alle mapper
   *[other] { $count } resultater for »{ $words }« i alle mapper
}
# review: new
win-search-found-in = { $count ->
    [0] Ingen resultater for »{ $words }« i { $folder }
    [one] { $count } resultat for »{ $words }« i { $folder }
   *[other] { $count } resultater for »{ $words }« i { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] indekserer stadig teksten i { $count } meddelelse
   *[other] indekserer stadig teksten i { $count } meddelelser
}
# review: new
win-no-match-indexing = { $count ->
    [one] Teksten i { $count } meddelelse indekseres stadig, så der findes måske snart flere.
   *[other] Teksten i { $count } meddelelser indekseres stadig, så der findes måske snart flere.
}
# review: new
win-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
# review: new
win-click-to-retry = Klik her for at prøve igen.
# review: new
win-save-attachments = &Gem vedhæftede filer...
# review: new
win-files-not-saved = { $failed } af de { $count } filer kunne ikke gemmes.
# review: new
win-new-folder-in-highlighted = Den nye mappe oprettes i den markerede mappe.
# review: new
win-delete-folder-ask = Vil du slette mappen »{ $folder }« med dens meddelelser og de mapper, den indeholder? Den slettes også på serveren.
# review: new
win-rename = &Omdøb...
# review: new
win-messages-not-saved = Meddelelserne kunne ikke gemmes.
# review: new
win-messages-not-forwarded = Meddelelserne kunne ikke videresendes.

## Accounts

# review: new
win-sign-in-google = Log ind med Google
# review: new
win-sign-in-microsoft = Log på med Microsoft
# review: new
win-next = &Næste >
# review: new
win-your-account = din konto
# review: new
win-browser-sign-in = (login via browser)
# review: new
win-add = &Tilføj...
# review: new
win-properties-button = &Egenskaber...
# review: new
win-signature-button = Si&gnatur...
# review: new
win-sign-in-apps-button = Login-a&pps...

## AI agents

# review: new
win-dont-allow = Tillad &ikke
# review: new
win-col-address = Adresse
# review: new
win-never-written-to = Aldrig skrevet til
# review: new
win-book-find-label = Skriv et navn eller en e-mailadresse:
# review: new
win-send = &Send
# review: new
win-dont-send = Send &ikke
# review: new
win-forget-program-ask = Vil du fjerne dette program, dets tilladelser og dets agenters aktivitetshistorik? Du bliver spurgt om tilladelse igen, næste gang det opretter forbindelse.
# review: new
win-clear-log-ask = Vil du rydde agenternes aktivitetshistorik? Det fortryder ikke de ændringer, agenterne har foretaget.
# review: new
win-agent-programs = &Programmer, hvis agenter har bedt om adgang til din mail:
# review: new
win-change = &Skift...
# review: new
win-what-agents-did = Agent&aktivitet:
# review: new
win-how-to-connect = Sådan forbinder du en agent

## Sign-in apps

# review: new
win-built-in = (indbygget)
# review: new
win-edit = &Rediger...

## Options

# review: new
win-options-language-label = &Vis Inbox Classic på:
# review: new
win-options-restart-note = Genstart Inbox Classic for at skifte sprog.
# review: new
win-options-notify = &Giv mig besked, når der kommer ny mail
# review: new
win-restart-ask = Inbox Classic vises på { $language }, når programmet er genstartet. Vil du genstarte nu?
# review: new
win-folders-hide = Skjul mappelisten
# review: new
win-folders-pin = Hold mappelisten ved siden af meddelelserne
# review: new
win-folders-show = Vis mapperne

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Start Inbox Classic
# review: new
win-installer-welcome-new =
    Dette installerer Inbox Classic { $version }, et e-mailprogram.

    Der kræves ingen administratorrettigheder, det installeres kun til din konto.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } er allerede installeret. Dette installerer det igen.

    Dine konti og din mail bevares.
# review: new
win-installer-welcome-update =
    Dette opdaterer Inbox Classic { $installed } til { $version }.

    Hvis programmet kører, lukkes det først. Dine konti og din mail bevares.
# review: new
win-installer-older-ask = Inbox Classic { $installed } er installeret, og den er nyere end { $version }. Vil du installere den ældre version alligevel?
# review: new
win-installer-still-running = Inbox Classic kører stadig. Luk programmet, og prøv igen.
# review: new
win-installer-remove-mail-ask = Vil du også fjerne de konti og den mail, Inbox Classic gemmer på denne computer? Mailen på serverne bliver, hvor den er.
