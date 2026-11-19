# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-.

## The main window

win-still-running-detail = Inbox Classic v ozadju še naprej preverja novo pošto. Kliknite ikono, da ga odprete. Za izhod z desno tipko miške kliknite ikono in uporabite njen meni.
win-default-app-not-installed = Ta kopija programa Inbox Classic ni bila nameščena, zato je Windows ne navaja kot poštni program. Namestite jo, da jo lahko izberete.
win-default-app-settings = Windows bo odprl nastavitve Privzete aplikacije. Izberite Inbox Classic za odpiranje povezav MAILTO.
win-no-unread = Ni neprebranih sporočil
win-unread-messages = { $count ->
    [one] { $count } neprebrano sporočilo
    [two] { $count } neprebrani sporočili
    [few] { $count } neprebrana sporočila
   *[other] { $count } neprebranih sporočil
}
win-print-failed = Sporočila ni bilo mogoče natisniti.
win-print-title-of = Natisni: { $subject }
win-no-bodies = Vsebine sporočil ni mogoče prikazati.
win-webview-failed = Ustvarjanje komponente WebView2 ni uspelo.
win-webview-missing = Izvajalno okolje WebView2 ni na voljo.
win-list-loading = Nalaganje...

## Buttons and words used in many windows

win-delete-button = &Izbriši
win-find-label = &Najdi:
win-save-as-button = S&hrani kot...
win-too-many-files = Preveč datotek naenkrat: izberite manj.

## The Outbox


## The compose window

win-editor-failed = Sporočil ni mogoče pisati.
win-ctrl-click-to-open = ({ $ctrl } + klik za odpiranje)
win-format-bold = Krepko ({ $ctrl }+B)
win-format-italic = Ležeče ({ $ctrl }+I)
win-format-underline = Podčrtano ({ $ctrl }+U)
win-format-link = Hiperpovezava ({ $ctrl }+K)
win-show-cc = &Kp
win-show-bcc = &Skp
win-signature-title = Besedilo podpisa: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Ni rezultatov za »{ $words }« v vseh mapah
    [one] { $count } rezultat za »{ $words }« v vseh mapah
    [two] { $count } rezultata za »{ $words }« v vseh mapah
    [few] { $count } rezultati za »{ $words }« v vseh mapah
   *[other] { $count } rezultatov za »{ $words }« v vseh mapah
}
win-search-found-in = { $count ->
    [0] Ni rezultatov za »{ $words }« v prikazu »{ $folder }«
    [one] { $count } rezultat za »{ $words }« v prikazu »{ $folder }«
    [two] { $count } rezultata za »{ $words }« v prikazu »{ $folder }«
    [few] { $count } rezultati za »{ $words }« v prikazu »{ $folder }«
   *[other] { $count } rezultatov za »{ $words }« v prikazu »{ $folder }«
}
win-search-indexing = { $count ->
    [one] besedilo { $count } sporočila se še indeksira
    [two] besedilo { $count } sporočil se še indeksira
    [few] besedilo { $count } sporočil se še indeksira
   *[other] besedilo { $count } sporočil se še indeksira
}
win-no-match-indexing = { $count ->
    [one] Besedilo { $count } sporočila se še indeksira, zato bo kmalu morda najdenih več zadetkov.
   *[other] Besedilo { $count } sporočil se še indeksira, zato bo kmalu morda najdenih več zadetkov.
}
win-files = { $count ->
    [one] { $count } datoteka
    [two] { $count } datoteki
    [few] { $count } datoteke
   *[other] { $count } datotek
}
win-click-to-retry = Kliknite tukaj, da poskusite znova.
win-save-attachments = &Shrani priponke...
win-files-not-saved = Datoteke, ki jih ni bilo mogoče shraniti: { $failed }. Skupno število datotek: { $count }.
win-new-folder-in-highlighted = Nova mapa bo ustvarjena v izbrani mapi.
win-delete-folder-ask = Želite izbrisati mapo »{ $folder }« z njenimi sporočili in mapami v njej? Izbrisana bo tudi na strežniku.
win-rename = &Preimenuj...
win-messages-not-saved = Sporočil ni bilo mogoče shraniti.
win-messages-not-forwarded = Sporočil ni bilo mogoče posredovati.

## Accounts

win-sign-in-google = Prijava z Googlom
win-sign-in-microsoft = Prijava z Microsoftom
win-next = &Naprej >
win-your-account = vaš račun
win-browser-sign-in = (prijava v brskalniku)
win-add = &Dodaj...
win-properties-button = &Lastnosti...
win-signature-button = Besedilo &podpisa...
win-sign-in-apps-button = &Aplikacije za prijavo...

## AI agents

win-dont-allow = &Ne dovoli
win-col-address = Naslov
win-never-written-to = Še niste pisali
win-book-find-label = Vnesite ime ali e-poštni naslov:
win-send = &Pošlji
win-dont-send = &Ne pošlji
win-unsubscribe = &Odjavi
win-dont-unsubscribe = &Ne odjavi
win-forget-program-ask = Želite odstraniti dovoljenja tega programa in zgodovino dejavnosti njegovih agentov? Ko se bo program naslednjič povezal, bo znova potreboval vaše dovoljenje.
win-clear-log-ask = Želite počistiti zgodovino dejavnosti agentov? Zapisi o branju bodo izbrisani, zapisi o spremembah pa skriti. Spremembe ne bodo razveljavljene, omejitve dejavnosti pa bodo ostale v veljavi.
win-agent-programs = &Programi, katerih agenti so zahtevali dostop do vaše pošte:
win-change = &Spremeni...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Razveljavi za o&bdobje...
win-take-back = &Razveljavi
win-what-agents-did = D&ejavnost agentov:
win-agent-reads = Kaj je bilo prebrano od { $from } do { $to }:
win-agent-reads-hint = Zgoraj izberite zapis o branju, da vidite, kaj je agent prebral.
win-how-to-connect = Kako povezati agenta

## Sign-in apps

win-built-in = (vgrajena)
win-edit = &Uredi...

## Options

win-folders-hide = Skrij seznam map
win-folders-pin = Seznam map naj bo ob sporočilih
win-folders-show = Pokaži mape

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Zaženi Inbox Classic
win-installer-welcome-new =
    Namestili boste Inbox Classic { $version }, program za e-pošto.

    Skrbniške pravice niso potrebne, program se namesti samo za vaš račun.
win-installer-welcome-same =
    Inbox Classic { $version } je že nameščen. Znova ga boste namestili.

    Vaši računi in pošta se ohranijo.
win-installer-welcome-update =
    Inbox Classic { $installed } boste posodobili na različico { $version }.

    Če se izvaja, se najprej zapre. Vaši računi in pošta se ohranijo.
win-installer-older-ask = Nameščen je Inbox Classic { $installed }, ki je novejši od { $version }. Želite vseeno namestiti starejšo različico?
win-installer-still-running = Inbox Classic se še izvaja. Zaprite ga in poskusite znova.
win-installer-remove-mail-ask = Želite odstraniti tudi vse lokalne podatke programa Inbox Classic, vključno z računi, pošto, stiki, ključi in nastavitvami? Pošta na strežnikih in prijavni podatki v sistemski shrambi ostanejo.
