# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-.

## The main window

# review: new
win-still-running-detail = Inbox Classic v ozadju še naprej preverja novo pošto. Kliknite ikono, da ga odprete. Za izhod z desno tipko miške kliknite ikono in uporabite njen meni.
# review: new
win-default-app-not-installed = Ta kopija programa Inbox Classic ni bila nameščena, zato je Windows ne navaja kot poštni program. Namestite jo, da jo lahko izberete.
# review: new
win-default-app-settings = Windows bo odprl nastavitve Privzete aplikacije. Izberite Inbox Classic za odpiranje povezav MAILTO.
# review: new
win-no-unread = Ni neprebranih sporočil
# review: new
win-unread-messages = { $count ->
    [one] { $count } neprebrano sporočilo
    [two] { $count } neprebrani sporočili
    [few] { $count } neprebrana sporočila
   *[other] { $count } neprebranih sporočil
}
# review: new
win-print-failed = Sporočila ni bilo mogoče natisniti.
# review: new
win-print-title-of = Natisni: { $subject }
# review: new
win-no-bodies = Vsebine sporočil ni mogoče prikazati.
# review: new
win-webview-failed = Ustvarjanje komponente WebView2 ni uspelo.
# review: new
win-webview-missing = Izvajalno okolje WebView2 ni na voljo.
win-list-loading = Nalaganje...

## Buttons and words used in many windows

# review: new
win-delete-button = &Izbriši
# review: new
win-find-label = &Najdi:
# review: new
win-save-as-button = Shrani &kot...
# review: new
win-too-many-files = Preveč datotek naenkrat: izberite manj.

## The Outbox


## The compose window

# review: new
win-editor-failed = Sporočil ni mogoče pisati.
# review: new
win-ctrl-click-to-open = ({ $ctrl } + klik za odpiranje)
# review: new
win-format-bold = Krepko ({ $ctrl }+B)
# review: new
win-format-italic = Ležeče ({ $ctrl }+I)
# review: new
win-format-underline = Podčrtano ({ $ctrl }+U)
# review: new
win-format-link = Hiperpovezava ({ $ctrl }+K)
# review: new
win-show-cc = &Kp
# review: new
win-show-bcc = &Skp
# review: new
win-signature-title = Podpis: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Ni rezultatov za »{ $words }« v vseh mapah
    [one] { $count } rezultat za »{ $words }« v vseh mapah
    [two] { $count } rezultata za »{ $words }« v vseh mapah
    [few] { $count } rezultati za »{ $words }« v vseh mapah
   *[other] { $count } rezultatov za »{ $words }« v vseh mapah
}
# review: new
win-search-found-in = { $count ->
    [0] Ni rezultatov za »{ $words }« v mapi { $folder }
    [one] { $count } rezultat za »{ $words }« v mapi { $folder }
    [two] { $count } rezultata za »{ $words }« v mapi { $folder }
    [few] { $count } rezultati za »{ $words }« v mapi { $folder }
   *[other] { $count } rezultatov za »{ $words }« v mapi { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] besedilo { $count } sporočila se še indeksira
    [two] besedilo { $count } sporočil se še indeksira
    [few] besedilo { $count } sporočil se še indeksira
   *[other] besedilo { $count } sporočil se še indeksira
}
# review: new
win-no-match-indexing = { $count ->
    [one] Besedilo { $count } sporočila se še indeksira, zato bo kmalu morda najdenih več zadetkov.
   *[other] Besedilo { $count } sporočil se še indeksira, zato bo kmalu morda najdenih več zadetkov.
}
# review: new
win-files = { $count ->
    [one] { $count } datoteka
    [two] { $count } datoteki
    [few] { $count } datoteke
   *[other] { $count } datotek
}
# review: new
win-click-to-retry = Kliknite tukaj, da poskusite znova.
# review: new
win-save-attachments = &Shrani priponke...
# review: new
win-files-not-saved = Ni bilo mogoče shraniti { $failed } od { $count } datotek.
# review: new
win-new-folder-in-highlighted = Nova mapa bo ustvarjena v izbrani mapi.
# review: new
win-delete-folder-ask = Želite izbrisati mapo »{ $folder }« z njenimi sporočili in mapami v njej? Izbrisana bo tudi na strežniku.
# review: new
win-rename = &Preimenuj...
# review: new
win-messages-not-saved = Sporočil ni bilo mogoče shraniti.
# review: new
win-messages-not-forwarded = Sporočil ni bilo mogoče posredovati.

## Accounts

# review: new
win-sign-in-google = Prijava z Googlom
# review: new
win-sign-in-microsoft = Prijava z Microsoftom
# review: new
win-next = &Naprej >
# review: new
win-your-account = vaš račun
# review: new
win-browser-sign-in = (prijava v brskalniku)
# review: new
win-add = &Dodaj...
# review: new
win-properties-button = &Lastnosti...
# review: new
win-signature-button = &Podpis...
# review: new
win-sign-in-apps-button = &Aplikacije za prijavo...

## AI agents

# review: new
win-dont-allow = &Ne dovoli
# review: new
win-col-address = Naslov
# review: new
win-never-written-to = Še niste pisali
# review: new
win-book-find-label = Vnesite ime ali e-poštni naslov:
# review: new
win-send = &Pošlji
# review: new
win-dont-send = &Ne pošlji
# review: new
win-forget-program-ask = Želite odstraniti ta program, njegova dovoljenja in zgodovino dejavnosti njegovih agentov? Ko se bo naslednjič povezal, boste znova vprašani za dovoljenje.
# review: new
win-clear-log-ask = Želite počistiti zgodovino dejavnosti agentov? S tem ne boste razveljavili sprememb, ki so jih naredili agenti.
# review: new
win-agent-programs = &Programi, katerih agenti so zahtevali dostop do vaše pošte:
# review: new
win-change = &Spremeni...
# review: new
win-what-agents-did = &Dejavnost agentov:
# review: new
win-how-to-connect = Kako povezati agenta

## Sign-in apps

# review: new
win-built-in = (vgrajena)
# review: new
win-edit = &Uredi...

## Options

# review: new
win-options-language-label = &Jezik programa Inbox Classic:
# review: new
win-options-restart-note = Za spremembo jezika znova zaženite Inbox Classic.
# review: new
win-options-notify = &Obvesti me, ko prispe nova pošta
# review: new
win-restart-ask = Inbox Classic bo po ponovnem zagonu v jeziku: { $language }. Želite znova zagnati zdaj?
# review: new
win-folders-hide = Skrij seznam map
# review: new
win-folders-pin = Seznam map naj bo ob sporočilih
# review: new
win-folders-show = Pokaži mape

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Zaženi Inbox Classic
# review: new
win-installer-welcome-new =
    Namestili boste Inbox Classic { $version }, program za e-pošto.

    Skrbniške pravice niso potrebne, program se namesti samo za vaš račun.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } je že nameščen. Znova ga boste namestili.

    Vaši računi in pošta se ohranijo.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } boste posodobili na različico { $version }.

    Če se izvaja, se najprej zapre. Vaši računi in pošta se ohranijo.
# review: new
win-installer-older-ask = Nameščen je Inbox Classic { $installed }, ki je novejši od { $version }. Želite vseeno namestiti starejšo različico?
# review: new
win-installer-still-running = Inbox Classic se še izvaja. Zaprite ga in poskusite znova.
# review: new
win-installer-remove-mail-ask = Želite odstraniti tudi račune in pošto, ki jih Inbox Classic hrani v tem računalniku? Pošta na strežnikih ostane.
